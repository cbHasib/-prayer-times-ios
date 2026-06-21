import SwiftUI
import PrayerKit

/// Fullscreen focus mode screen — shown during prayer times as a quiet discipline aid.
struct FocusOverlayView: View {
    let prayer: Prayer
    let clock: PrayerClock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Immersive brand green to dark charcoal gradient
            LinearGradient(
                colors: [
                    Color.brand,
                    Color(red: 0.08, green: 0.20, blue: 0.12),
                    Color(red: 0.04, green: 0.08, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Mosque logo with soft pulse animation
                Image("Mosque")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.15), radius: 24)

                VStack(spacing: 8) {
                    Text("Time for \(PrayerFormatting.name(prayer))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Pause and pray")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Countdown of remaining focus time
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    if let elapsed = timeElapsedSinceStart() {
                        let totalDuration = clock.isPreviewingFocus ? 10.0 : Double(clock.focusDuration) * 60
                        let remaining = max(0, totalDuration - elapsed)
                        VStack(spacing: 6) {
                            Text(PrayerFormatting.countdownLong(remaining))
                                .font(.system(size: 54, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.brandLight)

                            Text(clock.isPreviewingFocus ? "preview time remaining" : "focus time remaining")
                                .font(.caption)
                                .textCase(.uppercase)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                Button {
                    clock.dismissFocus()
                    dismiss()
                } label: {
                    Text(clock.isPreviewingFocus ? "Dismiss Preview" : (clock.emergencyExitEnabled ? "Dismiss" : "Close Focus"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 24)
            }
            .padding(24)
        }
    }

    private func timeElapsedSinceStart() -> TimeInterval? {
        if clock.isPreviewingFocus, let previewStart = clock.previewStartTime {
            return Date().timeIntervalSince(previewStart)
        }
        guard let time = clock.today.times[prayer] else { return nil }
        return Date().timeIntervalSince(time)
    }
}
