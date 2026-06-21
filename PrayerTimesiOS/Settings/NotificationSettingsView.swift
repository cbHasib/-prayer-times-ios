import SwiftUI
import PrayerKit

/// Notification settings — master toggle, per-prayer config, sound selection, test.
struct NotificationSettingsView: View {
    let settings: SettingsStore
    let audio: AudioService
    let notifications: NotificationService

    var body: some View {
        List {
            if notifications.authorizationStatus == .denied {
                Section {
                    Label {
                        Text("Notifications are disabled in iOS Settings. Please enable them to receive prayer alerts.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            Section {
                Toggle("Enable Notifications", isOn: Binding(
                    get: { settings.settings.masterNotificationsEnabled },
                    set: { settings.settings.masterNotificationsEnabled = $0 }
                ))
            }

            if settings.settings.masterNotificationsEnabled {
                Section {
                    HStack {
                        Button {
                            if audio.isPlaying {
                                audio.stop()
                            } else {
                                audio.preview(settings.settings.notificationDefaults.sound)
                            }
                        } label: {
                            Image(systemName: audio.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .foregroundStyle(settings.settings.notificationDefaults.sound == .none ? .secondary : Color.brand)
                                .font(.title3)
                        }
                        .disabled(settings.settings.notificationDefaults.sound == .none)
                        .buttonStyle(.plain)

                        Picker("Default Sound", selection: Binding(
                            get: { settings.settings.notificationDefaults.sound },
                            set: { settings.settings.notificationDefaults.sound = $0 }
                        )) {
                            ForEach(NotificationSound.allCases, id: \.self) { sound in
                                Text(PrayerFormatting.soundName(sound)).tag(sound)
                            }
                        }
                    }

                    Toggle("Play Full Adhan", isOn: Binding(
                        get: { settings.settings.notificationDefaults.playFullAdhan },
                        set: { settings.settings.notificationDefaults.playFullAdhan = $0 }
                    ))

                    Stepper(
                        "Early Reminder: \(settings.settings.notificationDefaults.earlyReminderMinutes) min",
                        value: Binding(
                            get: { settings.settings.notificationDefaults.earlyReminderMinutes },
                            set: { settings.settings.notificationDefaults.earlyReminderMinutes = $0 }
                        ),
                        in: 0...60,
                        step: 5
                    )

                    Stepper(
                        "Iqamah Offset: \(settings.settings.notificationDefaults.iqamahOffsetMinutes) min",
                        value: Binding(
                            get: { settings.settings.notificationDefaults.iqamahOffsetMinutes },
                            set: { settings.settings.notificationDefaults.iqamahOffsetMinutes = $0 }
                        ),
                        in: 0...60,
                        step: 5
                    )
                } header: {
                    Text("Defaults")
                } footer: {
                    Text("These defaults apply to all prayers unless overridden individually.")
                }

                Section {
                    ForEach(Prayer.allCases, id: \.self) { prayer in
                        HStack {
                            Image(systemName: PrayerFormatting.icon(prayer))
                                .foregroundStyle(Color.brand)
                                .frame(width: 24)
                            Text(PrayerFormatting.name(prayer))
                            Spacer()
                            if settings.settings.resolvedNotification(for: prayer).notify {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(Color.brand)
                                    .font(.caption)
                            } else {
                                Image(systemName: "bell.slash")
                                    .foregroundStyle(.tertiary)
                                    .font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("Per-Prayer Status")
                }

                Section {
                    Button {
                        Task { await notifications.sendSampleNotification() }
                    } label: {
                        Label("Send Test Notification", systemImage: "bell.badge.fill")
                    }
                } header: {
                    Text("Test")
                } footer: {
                    Text("Triggers an immediate test notification with the 'Takbir' sound so you can verify banner & sound settings.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notifications.refreshAuthorizationStatus()
        }
    }
}
