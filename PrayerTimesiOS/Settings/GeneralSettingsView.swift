import SwiftUI
import PrayerKit

/// General app settings — display preferences, Hijri date, about.
struct GeneralSettingsView: View {
    let settings: SettingsStore

    var body: some View {
        List {
            Section {
                Toggle("Show Hijri Date", isOn: Binding(
                    get: { settings.settings.showHijriDate },
                    set: { settings.settings.showHijriDate = $0 }
                ))

                if settings.settings.showHijriDate {
                    Stepper(
                        "Hijri Day Adjustment: \(settings.settings.hijriDayAdjustment)",
                        value: Binding(
                            get: { settings.settings.hijriDayAdjustment },
                            set: { settings.settings.hijriDayAdjustment = $0 }
                        ),
                        in: -2...2
                    )
                }
            } header: {
                Text("Display")
            } footer: {
                Text("Adjust the Hijri date to match your local moon-sighting.")
            }

            Section {
                Toggle("Show Ishraq Time", isOn: Binding(
                    get: { settings.settings.showIshraqTime },
                    set: { settings.settings.showIshraqTime = $0 }
                ))
            } header: {
                Text("Optional Times")
            } footer: {
                Text("Ishraq begins approximately 15 minutes after sunrise.")
            }

            Section {
                Button("Re-run Setup Wizard") {
                    settings.resetOnboarding()
                }
            } footer: {
                Text("Opens the first-launch setup wizard to reconfigure location and calculation method.")
            }
        }
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
    }
}
