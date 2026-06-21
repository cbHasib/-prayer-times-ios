import SwiftUI
import PrayerKit

/// First-launch onboarding wizard for iOS.
/// Guides through: Welcome → Location → Method → Notifications → Done.
struct OnboardingView: View {
    let settings: SettingsStore
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            locationPage.tag(1)
            methodPage.tag(2)
            notificationPage.tag(3)
            completionPage.tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .interactiveDismissDisabled()
    }

    // MARK: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("Mosque")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.brand)

            Text("Prayer Times")
                .font(.largeTitle.bold())

            Text("Accurate Islamic prayer times with Adhan notifications, multiple calculation methods, and a beautiful countdown.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            nextButton("Get Started")
        }
        .padding(24)
    }

    // MARK: Location

    private var locationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)

            Text("Your Location")
                .font(.title.bold())

            Text("Prayer times are calculated based on your geographic location. Enable automatic detection or enter coordinates manually.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Picker("", selection: Binding(
                get: { settings.settings.locationMode },
                set: { settings.setLocationMode($0) }
            )) {
                Text("Automatic").tag(LocationMode.automatic)
                Text("Manual").tag(LocationMode.manual)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 48)

            if settings.isDetectingLocation {
                HStack {
                    ProgressView()
                    Text("Detecting…")
                        .foregroundStyle(.secondary)
                }
            } else if settings.detectedCoordinates != nil {
                Label("Location detected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.brand)
            } else if settings.settings.locationMode == .automatic {
                Button("Detect Location") {
                    Task { await settings.detectLocation() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brand)
            }

            Spacer()

            nextButton("Continue")
        }
        .padding(24)
    }

    // MARK: Method

    private var methodPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "function")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)

            Text("Calculation Method")
                .font(.title.bold())

            Text("Choose how prayer times are calculated. Auto-detect picks the best method for your country.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Toggle("Auto-detect by country", isOn: Binding(
                get: { settings.settings.autoDetectMethod },
                set: { settings.settings.autoDetectMethod = $0 }
            ))
            .padding(.horizontal, 48)

            if let label = settings.autoMethodLabel {
                Text(label)
                    .font(.callout)
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, 48)
            }

            Spacer()

            nextButton("Continue")
        }
        .padding(24)
    }

    // MARK: Notifications

    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)

            Text("Notifications")
                .font(.title.bold())

            Text("Get notified at each prayer time with customizable Adhan sounds. You can configure per-prayer notifications later in Settings.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Toggle("Enable Notifications", isOn: Binding(
                get: { settings.settings.masterNotificationsEnabled },
                set: { settings.settings.masterNotificationsEnabled = $0 }
            ))
            .padding(.horizontal, 48)

            Spacer()

            nextButton("Continue")
        }
        .padding(24)
    }

    // MARK: Completion

    private var completionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brand)
                .symbolEffect(.bounce, options: .nonRepeating, value: currentPage)

            Text("You're All Set!")
                .font(.largeTitle.bold())

            Text("Prayer times are ready. You can adjust all settings anytime from the gear icon.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Start Using Prayer Times")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .padding(.horizontal, 24)
        }
        .padding(24)
    }

    // MARK: Helper

    private func nextButton(_ title: String) -> some View {
        Button {
            withAnimation {
                currentPage += 1
            }
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.brand)
        .padding(.horizontal, 24)
    }
}
