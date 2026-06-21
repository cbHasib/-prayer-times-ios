import SwiftUI
import PrayerKit

/// Settings screen — replaces the macOS tabbed settings window.
struct SettingsView: View {
    let settings: SettingsStore
    let clock: PrayerClock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CalculationSettingsView(settings: settings)
                    } label: {
                        Label("Calculation Method", systemImage: "function")
                    }

                    NavigationLink {
                        LocationSettingsView(settings: settings)
                    } label: {
                        Label("Location & Time", systemImage: "location.fill")
                    }

                    NavigationLink {
                        FocusModeSettingsView(settings: settings, clock: clock)
                    } label: {
                        Label("Focus Mode", systemImage: "eye.slash.fill")
                    }

                    NavigationLink {
                        NotificationSettingsView(settings: settings, audio: clock.audio, notifications: clock.notifications)
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }

                Section {
                    NavigationLink {
                        GeneralSettingsView(settings: settings)
                    } label: {
                        Label("General", systemImage: "gearshape")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/hasib/prayer-time-ios")!) {
                        HStack {
                            Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/tareq1988/prayer-times-macos")!) {
                        HStack {
                            Label("Original macOS App", systemImage: "macwindow")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
