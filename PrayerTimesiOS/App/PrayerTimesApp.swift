import SwiftUI

/// iOS app entry point. Uses a standard `WindowGroup` scene with a navigation-based
/// UI instead of the macOS `MenuBarExtra`. Services are initialized here and injected
/// via SwiftUI's environment/state system.
@main
struct PrayerTimesApp: App {
    @State private var settings: SettingsStore
    @State private var clock: PrayerClock
    @State private var showOnboarding: Bool

    init() {
        let location = LocationService()
        let settings = SettingsStore(location: location)
        let audio = AudioService()
        let notifications = NotificationService(audio: audio)
        _settings = State(initialValue: settings)
        _clock = State(initialValue: PrayerClock(settings: settings, notifications: notifications, audio: audio))
        _showOnboarding = State(initialValue: settings.needsOnboarding)

        // Auto-detect on launch when the user is in automatic mode.
        Task { await settings.detectLocationIfNeeded() }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(clock: clock, settings: settings)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(settings: settings) {
                        settings.completeOnboarding()
                        showOnboarding = false
                    }
                }
        }
    }
}
