import Foundation
import UserNotifications
import PrayerKit
import OSLog
import Observation

/// Schedules local notifications for the rolling today + tomorrow window.
/// Adapted from macOS: uses the same `UNUserNotificationCenter` API (cross-platform),
/// with minor adjustments to the notification sound strategy for iOS.
@MainActor
@Observable
final class NotificationService: NSObject {
    @ObservationIgnored private let audio: AudioService
    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private let log = Logger(subsystem: "co.tareq.prayertimes.ios", category: "notifications")

    /// The current system authorization status.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private nonisolated static let adhanCategoryID = "PRAYER_ADHAN"
    private nonisolated static let stopAdhanActionID = "STOP_ADHAN"

    init(audio: AudioService) {
        self.audio = audio
        super.init()
        center.delegate = self
        registerCategories()
    }

    /// Request alert/sound/badge authorization.
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            log.notice("Notification authorization granted=\(granted)")
        } catch {
            log.error("Authorization error: \(error.localizedDescription, privacy: .public)")
        }
        await refreshAuthorizationStatus()
    }

    /// Re-read the system authorization status.
    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    /// Fire an immediate sample notification so the user can preview.
    func sendSampleNotification() async {
        await requestAuthorization()

        let name = PrayerFormatting.name(.dhuhr)
        let clock = PrayerFormatting.clock(Date(), in: .current)

        let content = UNMutableNotificationContent()
        content.title = name
        content.body = String(localized: "It's time for \(name) (\(clock)).")
        content.sound = UNNotificationSound(named: UNNotificationSoundName("takbir.caf"))

        let request = UNNotificationRequest(
            identifier: "SAMPLE-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        do {
            try await center.add(request)
            log.notice("Sent sample notification")
        } catch {
            log.error("Sample notification failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Replace all scheduled notifications with a fresh set for the given days.
    func reschedule(today: PrayerTimes, tomorrow: PrayerTimes, settings: AppSettings,
                    timeZone: TimeZone, now: Date) {
        center.removeAllPendingNotificationRequests()
        guard settings.masterNotificationsEnabled else {
            log.debug("Master notifications off; cleared schedule")
            return
        }

        let manual = settings.calculationMode == .manual
        let azanBefore = manual ? Double(max(0, settings.azanBeforeJamaat)) * 60 : 0

        var requests: [UNNotificationRequest] = []
        for day in [today, tomorrow] {
            let dayKey = Self.dayKey(day.date, in: timeZone)
            for (prayer, time) in day.times {
                let cfg = settings.resolvedNotification(for: prayer)

                // Prayer-entry notification
                if cfg.notify {
                    let fireAt = (manual && prayer.isObligatory)
                        ? time.addingTimeInterval(-azanBefore) : time
                    let name = PrayerFormatting.name(prayer)
                    let clock = PrayerFormatting.clock(time, in: timeZone)
                    requests.append(contentsOf: request(
                        id: "PRAYER-\(dayKey)-\(prayer.rawValue)",
                        fireAt: fireAt, now: now,
                        title: name,
                        body: String(localized: "It's time for \(name) (\(clock))."),
                        sound: soundForEntry(cfg),
                        categoryID: cfg.playFullAdhan ? Self.adhanCategoryID : nil
                    ))
                }

                // Early reminder
                if cfg.earlyReminderEnabled {
                    let early = time.addingTimeInterval(Double(-cfg.earlyLeadMinutes) * 60)
                    let name = PrayerFormatting.name(prayer)
                    let clock = PrayerFormatting.clock(time, in: timeZone)
                    requests.append(contentsOf: request(
                        id: "EARLY-\(dayKey)-\(prayer.rawValue)",
                        fireAt: early, now: now,
                        title: String(localized: "\(name) in \(cfg.earlyLeadMinutes) min"),
                        body: String(localized: "\(name) is at \(clock)."),
                        sound: .default,
                        categoryID: nil
                    ))
                }

                // Iqamah notification
                if prayer.isObligatory, !manual, cfg.iqamahOffsetMinutes > 0 {
                    let iqamah = time.addingTimeInterval(Double(cfg.iqamahOffsetMinutes) * 60)
                    let name = PrayerFormatting.name(prayer)
                    let clock = PrayerFormatting.clock(iqamah, in: timeZone)
                    requests.append(contentsOf: request(
                        id: "IQAMAH-\(dayKey)-\(prayer.rawValue)",
                        fireAt: iqamah, now: now,
                        title: String(localized: "Iqamah — \(name)"),
                        body: String(localized: "Congregation at \(clock)."),
                        sound: .default,
                        categoryID: nil
                    ))
                }
            }
        }

        for request in requests {
            let id = request.identifier
            center.add(request) { [log] error in
                if let error {
                    log.error("Schedule failed \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        log.notice("Scheduled \(requests.count) notifications")
    }

    // MARK: Building requests

    private func request(id: String, fireAt: Date, now: Date,
                         title: String, body: String,
                         sound: UNNotificationSound?, categoryID: String?) -> [UNNotificationRequest] {
        let interval = fireAt.timeIntervalSince(now)
        guard interval > 0.5 else { return [] }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        if let categoryID { content.categoryIdentifier = categoryID }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        return [UNNotificationRequest(identifier: id, content: content, trigger: trigger)]
    }

    /// On iOS, notification sounds are more reliable, so we can attach clip sounds
    /// directly to the notification content. Full Adhan still plays in-process.
    private func soundForEntry(_ cfg: ResolvedNotification) -> UNNotificationSound? {
        switch cfg.sound {
        case .none: return nil
        case .systemDefault: return .default
        case .softChime:
            return UNNotificationSound(named: UNNotificationSoundName("soft-chime.caf"))
        case .takbir:
            return UNNotificationSound(named: UNNotificationSoundName("takbir.caf"))
        case .adhanMakkah, .adhanMadinah:
            // Full adhan plays in-process; notification gets a short takbir clip
            return UNNotificationSound(named: UNNotificationSoundName("takbir.caf"))
        }
    }

    private func registerCategories() {
        let stop = UNNotificationAction(identifier: Self.stopAdhanActionID,
                                        title: "Stop Adhan", options: [.foreground])
        let category = UNNotificationCategory(identifier: Self.adhanCategoryID,
                                              actions: [stop], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    private static func dayKey(_ date: Date, in timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show banners even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    /// Handle the Stop-Adhan action.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.actionIdentifier == Self.stopAdhanActionID {
            await audio.stop()
        }
    }
}
