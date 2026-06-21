import Foundation
import UIKit
import Observation
import WidgetKit
import PrayerKit

/// The single source of truth for user configuration. Adapted from macOS:
/// replaced `AppKit` with `UIKit`, removed macOS-only features (login items,
/// Sparkle updates, Focus Mode, NSWorkspace relaunch, menu bar migrations).
@MainActor
@Observable
final class SettingsStore {

    /// Editing this struct anywhere (incl. via SwiftUI bindings) re-persists it.
    var settings: AppSettings {
        didSet { persist() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "appSettings.v1"
    @ObservationIgnored private let location: LocationService

    @ObservationIgnored private let isFirstRun: Bool

    // Runtime auto-detect state (not persisted).
    private(set) var detectedCoordinates: Coordinates?
    private(set) var detectedCountryCode: String?
    private(set) var detectedTimeZoneID: String?
    private(set) var isDetectingLocation = false
    private(set) var locationError: String?

    static let appGroupSuite: String? = "group.co.hasib.prayertimes"

    init(location: LocationService, defaults: UserDefaults? = nil) {
        self.location = location
        let resolved = defaults
            ?? Self.appGroupSuite.flatMap { UserDefaults(suiteName: $0) }
            ?? .standard
        self.defaults = resolved
        let loaded = Self.load(from: resolved, key: key)
        self.isFirstRun = (loaded == nil)
        self.settings = loaded ?? Self.firstRunDefaults
        migrateHighLatitudeRuleIfNeeded()
        migrateOnboardingIfNeeded(wasFirstRun: loaded == nil)
    }

    private func migrateOnboardingIfNeeded(wasFirstRun: Bool) {
        guard !wasFirstRun, !settings.didCompleteOnboarding else { return }
        settings.didCompleteOnboarding = true
    }

    // MARK: Onboarding

    var needsOnboarding: Bool { !settings.didCompleteOnboarding }
    func completeOnboarding() { settings.didCompleteOnboarding = true }
    func resetOnboarding() { settings.didCompleteOnboarding = false }

    private func migrateHighLatitudeRuleIfNeeded() {
        let flag = "didMigrateHighLatAutomatic.v1"
        guard !defaults.bool(forKey: flag) else { return }
        defaults.set(true, forKey: flag)
        if settings.highLatitudeRule == .none {
            settings.highLatitudeRule = .automatic
        }
    }

    // MARK: Resolved inputs

    var resolvedCoordinates: Coordinates {
        if settings.locationMode == .automatic, let detected = detectedCoordinates {
            return detected
        }
        return settings.manualCoordinates ?? Self.defaultCoordinates
    }

    var autoMethodLabel: String? {
        guard settings.autoDetectMethod else { return nil }
        guard let code = detectedCountryCode else { return String(localized: "Auto-detect on — locating…") }
        let country = Locale.current.localizedString(forRegionCode: code) ?? code
        return String(localized: "Auto: \(resolvedMethodName) (\(country))")
    }

    // MARK: Auto-detect (CoreLocation)

    func detectLocationIfNeeded() async {
        let wantsAuto = settings.locationMode == .automatic || settings.autoDetectMethod
        guard wantsAuto else { return }
        let authorized = location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
        guard authorized || isFirstRun else { return }
        await detectLocation()
    }

    func setLocationMode(_ mode: LocationMode) {
        if mode == .manual {
            settings.manualCoordinates = resolvedCoordinates
        }
        settings.locationMode = mode
        if mode == .automatic {
            Task { await detectLocation() }
        }
    }

    func detectLocation() async {
        guard !isDetectingLocation else { return }
        isDetectingLocation = true
        locationError = nil
        defer { isDetectingLocation = false }
        do {
            let loc = try await location.fetchCurrent()
            detectedCoordinates = Coordinates(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                elevation: loc.altitude
            )
            if let data = try? JSONEncoder().encode(detectedCoordinates) {
                defaults.set(data, forKey: "detectedCoordinates.v1")
            }
            let place = await location.place(for: loc)
            detectedCountryCode = place.countryCode
            detectedTimeZoneID = place.timeZone?.identifier
            if settings.autoDetectMethod, let code = place.countryCode {
                settings.methodID = MethodRegistry.methodID(forCountryCode: code)
            }
            if let tz = place.timeZone, tz.identifier != resolvedTimeZone.identifier {
                settings.timeZoneMode = .explicit(identifier: tz.identifier)
            }
        } catch {
            locationError = error.localizedDescription
        }
    }

    var timeZoneMismatchWarning: String? {
        guard settings.locationMode == .automatic,
              let detected = detectedTimeZoneID,
              detected != resolvedTimeZone.identifier
        else { return nil }
        return String(localized:
            "Your timezone (\(resolvedTimeZone.identifier)) doesn't match your detected location (\(detected)). Prayer times may be wrong.")
    }

    var resolvedTimeZone: TimeZone {
        settings.timeZoneMode.timeZone
    }

    func resolvedAdapter() -> any CalculationMethodAdapter {
        MethodRegistry.resolve(
            methodID: settings.methodID,
            hanafiAsr: settings.hanafiAsr,
            manualParameters: settings.manualParameters
        ) ?? MWLAdapter()
    }

    var resolvedMethodName: String {
        resolvedAdapter().displayName
    }

    func resolvedParameters() -> CalculationParameters {
        var p = resolvedAdapter().resolve(for: resolvedCoordinates)
        if settings.highLatitudeRule != .automatic {
            p.highLatitudeRule = settings.highLatitudeRule
        }
        return p
    }

    var resolvedInputs: ResolvedInputs {
        ResolvedInputs(
            coordinates: resolvedCoordinates,
            timeZoneID: resolvedTimeZone.identifier,
            parameters: resolvedParameters(),
            manual: resolvedManualSchedule
        )
    }

    var resolvedManualSchedule: ManualSchedule? {
        guard settings.calculationMode == .manual else { return nil }
        return ManualSchedule(
            jamaatMinutes: settings.jamaatTimes,
            azanBeforeJamaat: settings.azanBeforeJamaat,
            keepWaqt: settings.manualKeepWaqt
        )
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func load(from defaults: UserDefaults, key: String) -> AppSettings? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }

    // MARK: Defaults

    static let defaultCoordinates = Coordinates(latitude: 41.0082, longitude: 28.9784)

    static var firstRunDefaults: AppSettings {
        AppSettings(
            methodID: "mwl",
            locationMode: .automatic,
            manualCoordinates: defaultCoordinates,
            timeZoneMode: .system,
            autoDetectMethod: true
        )
    }
}

/// The minimal, `Equatable` set of inputs that determine the prayer times.
struct ResolvedInputs: Equatable {
    var coordinates: Coordinates
    var timeZoneID: String
    var parameters: CalculationParameters
    var manual: ManualSchedule?
}


