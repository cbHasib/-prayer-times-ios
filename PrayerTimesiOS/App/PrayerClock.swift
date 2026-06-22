import Foundation
import Observation
import PrayerKit
import ActivityKit

/// The live clock that drives the iOS app. It computes today's (and tomorrow's)
/// prayer times from `PrayerKit` using the current `SettingsStore` inputs, tracks
/// the current instant once per second for the countdown, and recomputes on day
/// rollover or whenever a setting that affects the times changes.
///
/// Adapted from the macOS version: removed App Nap activity, FocusModeController
/// dependency, and focus-mode crossing logic (macOS-only concepts).
@MainActor
@Observable
final class PrayerClock {

    private let settings: SettingsStore
    let notifications: NotificationService
    let audio: AudioService

    // MARK: Live state
    private(set) var today: PrayerTimes
    private(set) var tomorrow: PrayerTimes
    private(set) var now: Date
    var activeFocusPrayer: Prayer?
    var pendingFocusPreview = false
    private(set) var isPreviewingFocus = false
    private(set) var previewStartTime: Date? = nil
    private var dismissedFocusPrayers = Set<String>()
    
    private var lastLiveActivityNextTime: Date? = nil
    private var lastLiveActivityEnabled = false

    /// Cached inputs the current `today`/`tomorrow` were computed from, plus the
    /// civil day, so `tick()` can detect both setting changes and rollover.
    private var lastInputs: ResolvedInputs
    private var lastDay: Date
    /// Previous tick instant, used to detect when a prayer time was just crossed.
    private var previousNow: Date

    private var tickTask: Task<Void, Never>?

    init(settings: SettingsStore, notifications: NotificationService, audio: AudioService) {
        self.settings = settings
        self.notifications = notifications
        self.audio = audio
        let start = Date()
        now = start
        previousNow = start
        let inputs = settings.resolvedInputs
        lastInputs = inputs
        let tz = TimeZone(identifier: inputs.timeZoneID) ?? .current
        lastDay = Self.civilDay(of: start, in: tz)
        today = Self.compute(inputs: inputs, dayOffset: 0, from: start)
        tomorrow = Self.compute(inputs: inputs, dayOffset: 1, from: start)

        // Immediate schedule covers the common relaunch case (permission already
        // granted). On a fresh install the authorization prompt resolves
        // asynchronously, so reschedule once it does.
        scheduleNotifications()
        startTicking()
        updateLiveActivity(force: true)
        Task { [weak self] in
            await notifications.requestAuthorization()
            self?.scheduleNotifications()
        }
    }

    // MARK: Derived values (read live from settings)

    var coordinates: Coordinates { settings.resolvedCoordinates }
    var timeZone: TimeZone { settings.resolvedTimeZone }
    var methodName: String { settings.resolvedMethodName }

    /// The upcoming prayer: the next one today, or tomorrow's Fajr after Isha.
    var nextEvent: (prayer: Prayer, time: Date)? {
        today.next(after: now) ?? tomorrow.next(after: now)
    }

    /// Seconds remaining until the next prayer (never negative).
    var secondsUntilNext: TimeInterval {
        guard let next = nextEvent else { return 0 }
        return max(0, next.time.timeIntervalSince(now))
    }

    /// The prayer window currently in progress (for the "time left" countdown).
    var currentWaqt: CurrentWaqt? {
        CurrentWaqt.resolve(at: now, today: today, tomorrow: tomorrow)
    }

    /// Today's Ishraq start (sunrise + fixed offset), for the optional panel line.
    var ishraqTime: Date? { today.ishraq() }

    /// Whether the user enabled the optional Ishraq line.
    var showsIshraqTime: Bool { settings.settings.showIshraqTime }

    /// Whether the panel shows the Hijri date line.
    var showsHijriDate: Bool { settings.settings.showHijriDate }

    /// Whole-day correction applied to the displayed Hijri date.
    var hijriDayAdjustment: Int { settings.settings.hijriDayAdjustment }

    /// Today's six times in chronological order.
    var orderedToday: [(prayer: Prayer, time: Date)] { today.ordered }

    /// Whether the full Adhan is currently playing (drives the Stop control).
    var isAdhanPlaying: Bool { audio.isPlaying }

    /// Stop in-process Adhan playback.
    func stopAdhan() { audio.stop() }

    /// Iqamah instant for a prayer, if an offset is configured (obligatory only).
    func iqamahTime(for prayer: Prayer, prayerTime: Date) -> Date? {
        guard prayer.isObligatory, settings.settings.calculationMode == .calculated else { return nil }
        let offset = settings.settings.resolvedNotification(for: prayer).iqamahOffsetMinutes
        guard offset > 0 else { return nil }
        return prayerTime.addingTimeInterval(Double(offset) * 60)
    }

    // MARK: Ticking, rollover & settings changes

    private func startTicking() {
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                self.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func tick() {
        now = Date()
        let inputs = settings.resolvedInputs
        let tz = TimeZone(identifier: inputs.timeZoneID) ?? .current
        let day = Self.civilDay(of: now, in: tz)
        var forceActivityUpdate = false
        if inputs != lastInputs || day != lastDay {
            lastInputs = inputs
            lastDay = day
            today = Self.compute(inputs: inputs, dayOffset: 0, from: now)
            tomorrow = Self.compute(inputs: inputs, dayOffset: 1, from: now)
            scheduleNotifications()
            forceActivityUpdate = true
        }
        firePrayerSoundIfCrossed(from: previousNow, to: now)
        updateFocusModeState()
        updateLiveActivity(force: forceActivityUpdate)
        previousNow = now
    }

    // MARK: Focus Mode State

    var focusDuration: Int { settings.settings.focusDurationMinutes }
    var emergencyExitEnabled: Bool { settings.settings.focusEmergencyExitEnabled }

    func dismissFocus() {
        guard let prayer = activeFocusPrayer else { return }
        if isPreviewingFocus {
            isPreviewingFocus = false
            previewStartTime = nil
            activeFocusPrayer = nil
            audio.stop()
            return
        }
        let dayKey = Self.dayKey(today.date, in: timeZone)
        let instanceKey = "\(dayKey)-\(prayer.rawValue)"
        dismissedFocusPrayers.insert(instanceKey)
        activeFocusPrayer = nil
    }

    func previewFocus() {
        isPreviewingFocus = true
        previewStartTime = Date()
        activeFocusPrayer = .dhuhr
        
        // Auto-play adhan sound if focus sound is enabled!
        if settings.settings.focusPlaySoundEnabled {
            let sound = settings.settings.notificationDefaults.sound
            let soundToPlay = sound.hasFullAdhan ? sound : .adhanMakkah
            audio.playFullAdhan(soundToPlay)
        }
        
        Task {
            try? await Task.sleep(for: .seconds(10))
            if isPreviewingFocus && activeFocusPrayer == .dhuhr {
                activeFocusPrayer = nil
                isPreviewingFocus = false
                previewStartTime = nil
                audio.stop()
            }
        }
    }

    func previewFocusSound() {
        audio.stop()
        let sound = settings.settings.notificationDefaults.sound
        let soundToPlay = sound.hasFullAdhan ? sound : .adhanMakkah
        audio.playFullAdhan(soundToPlay)
        Task {
            try? await Task.sleep(for: .seconds(10))
            audio.stop()
        }
    }

    private func updateFocusModeState() {
        if isPreviewingFocus { return }
        guard settings.settings.focusModeEnabled else {
            activeFocusPrayer = nil
            return
        }
        let duration = Double(settings.settings.focusDurationMinutes) * 60
        var foundActiveFocus: Prayer? = nil

        for (prayer, time) in today.ordered {
            if settings.settings.focusTrigger.includes(prayer) {
                let elapsed = now.timeIntervalSince(time)
                if elapsed >= 0 && elapsed < duration {
                    let dayKey = Self.dayKey(today.date, in: timeZone)
                    let instanceKey = "\(dayKey)-\(prayer.rawValue)"
                    if !dismissedFocusPrayers.contains(instanceKey) {
                        foundActiveFocus = prayer
                        break
                    }
                }
            }
        }
        self.activeFocusPrayer = foundActiveFocus
    }

    private func updateLiveActivity(force: Bool = false) {
        #if canImport(ActivityKit)
        let enabled = settings.settings.focusDynamicIslandEnabled
        let activeFocus = activeFocusPrayer

        // Only show Live Activity when focus Dynamic Island is enabled AND we are actively in focus mode (either real or preview)
        guard enabled, let prayer = activeFocus else {
            // End all activities if disabled or not in focus mode
            Task { @MainActor in
                for activity in Activity<PrayerActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            lastLiveActivityNextTime = nil
            lastLiveActivityEnabled = enabled
            return
        }

        let focusEndTime: Date
        if isPreviewingFocus {
            focusEndTime = (previewStartTime ?? Date()).addingTimeInterval(10)
        } else {
            guard let prayerTime = today.times[prayer] else { return }
            focusEndTime = prayerTime.addingTimeInterval(Double(settings.settings.focusDurationMinutes) * 60)
        }

        guard force || focusEndTime != lastLiveActivityNextTime || enabled != lastLiveActivityEnabled else {
            return
        }

        lastLiveActivityNextTime = focusEndTime
        lastLiveActivityEnabled = enabled

        var todayPrayersDict: [String: Date] = [:]
        for (p, date) in today.times {
            todayPrayersDict[p.rawValue] = date
        }

        let state = PrayerActivityAttributes.ContentState(
            nextPrayerName: PrayerFormatting.name(prayer),
            nextPrayerTime: focusEndTime,
            secondsUntilNext: focusEndTime.timeIntervalSince(Date())
        )

        // Find existing activity
        if Activity<PrayerActivityAttributes>.activities.first != nil {
            Task { @MainActor in
                if let existing = Activity<PrayerActivityAttributes>.activities.first {
                    await existing.update(ActivityContent(state: state, staleDate: nil))
                }
            }
        } else {
            // Request a new activity
            let attributes = PrayerActivityAttributes(todayPrayers: todayPrayersDict)
            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
        #endif
    }

    private static func dayKey(_ date: Date, in timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Reschedule the rolling notification window from current settings/times.
    private func scheduleNotifications() {
        notifications.reschedule(
            today: today, tomorrow: tomorrow,
            settings: settings.settings, timeZone: timeZone, now: now
        )
    }

    /// Play the prayer's chosen sound in-process for any prayer whose instant
    /// falls in `(start, end]`. On iOS the notification sound is more reliable
    /// than macOS, but we still play in-process for the full Adhan.
    private static let maxAdhanCatchUp: TimeInterval = 10
    private func firePrayerSoundIfCrossed(from start: Date, to end: Date) {
        guard settings.settings.masterNotificationsEnabled else { return }
        guard end.timeIntervalSince(start) <= Self.maxAdhanCatchUp else { return }
        for (prayer, time) in today.times where time > start && time <= end {
            let cfg = settings.settings.resolvedNotification(for: prayer)
            guard cfg.notify else { continue }
            if cfg.playFullAdhan, cfg.sound.hasFullAdhan {
                audio.playFullAdhan(cfg.sound)
            } else {
                audio.playClip(cfg.sound)
            }
        }
    }

    // MARK: Engine bridge

    private static func compute(inputs: ResolvedInputs, dayOffset: Int, from reference: Date) -> PrayerTimes {
        let tz = TimeZone(identifier: inputs.timeZoneID) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let day = cal.date(byAdding: .day, value: dayOffset, to: reference) ?? reference
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        let astronomical = PrayerTimeEngine.calculate(
            date: comps,
            coordinates: inputs.coordinates,
            params: inputs.parameters,
            timeZone: tz
        )
        guard let manual = inputs.manual else { return astronomical }
        return manual.applied(to: astronomical, day: day, timeZone: tz)
    }

    private static func civilDay(of date: Date, in timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.startOfDay(for: date)
    }
}
