import SwiftUI
import PrayerKit

/// Focus Mode settings — toggles, duration, trigger conditions, and emergency exits.
struct FocusModeSettingsView: View {
    @Bindable var settings: SettingsStore
    let clock: PrayerClock

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Toggle("Enable Focus Mode", isOn: $settings.settings.focusModeEnabled)
            } footer: {
                Text("Covers your screen at prayer times as a quiet discipline aid to encourage stepping away to pray.")
            }

            if settings.settings.focusModeEnabled {
                Section {
                    Stepper(
                        "Duration: \(settings.settings.focusDurationMinutes) min",
                        value: $settings.settings.focusDurationMinutes,
                        in: 5...60,
                        step: 5
                    )

                    Picker("Trigger On", selection: $settings.settings.focusTrigger) {
                        Text("Obligatory Prayers").tag(FocusTrigger.obligatory)
                        Text("All Tracked Times").tag(FocusTrigger.all)
                        Text("Fajr & Isha Only").tag(FocusTrigger.fajrIsha)
                    }

                    Toggle("Enable Dismiss Button", isOn: $settings.settings.focusEmergencyExitEnabled)
                } header: {
                    Text("Configuration")
                } footer: {
                    Text("The focus cover will dismiss automatically after the duration. If the dismiss button is disabled, the overlay is persistent to aid discipline.")
                }

                Section {
                    Button {
                        clock.pendingFocusPreview = true
                        dismiss()
                    } label: {
                        Label("Preview Focus Mode (10s)", systemImage: "eye.fill")
                    }
                } header: {
                    Text("Preview")
                } footer: {
                    Text("Dismisses settings and displays a sample Focus Mode screen for 10 seconds to preview the layout.")
                }
            }
        }
        .navigationTitle("Focus Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
