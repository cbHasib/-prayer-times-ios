import SwiftUI
import PrayerKit

/// The main screen of the iOS app — replaces the macOS `MenuBarPanel`.
/// Shows a hero countdown to the next prayer, today's prayer times list,
/// and navigation to settings.
struct HomeView: View {
    let clock: PrayerClock
    let settings: SettingsStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    dateHeader
                    countdownHero
                    prayerTimesList
                    if clock.isAdhanPlaying {
                        stopAdhanButton
                    }
                    methodSummary
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Prayer Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.brand)
                    }
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: {
                if clock.pendingFocusPreview {
                    clock.pendingFocusPreview = false
                    clock.previewFocus()
                }
            }) {
                SettingsView(settings: settings, clock: clock)
            }
            .fullScreenCover(isPresented: Binding(
                get: { clock.activeFocusPrayer != nil },
                set: { if !$0 { clock.dismissFocus() } }
            )) {
                if let prayer = clock.activeFocusPrayer {
                    FocusOverlayView(prayer: prayer, clock: clock)
                }
            }
        }
    }

    // MARK: Date Header

    private var dateHeader: some View {
        VStack(spacing: 6) {
            Image("Mosque")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Color.brand)
                .padding(.bottom, 2)

            Text(PrayerFormatting.longDate(clock.now, in: clock.timeZone))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            if clock.showsHijriDate {
                Text(PrayerFormatting.hijriDate(clock.now, in: clock.timeZone, adjustment: clock.hijriDayAdjustment))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: Countdown Hero

    private var countdownHero: some View {
        VStack(spacing: 12) {
            if let next = clock.nextEvent {
                HStack(spacing: 12) {
                    Image(systemName: PrayerFormatting.icon(next.prayer))
                        .font(.title)
                        .foregroundStyle(Color.brand)
                        .frame(width: 44, height: 44)
                        .background(Color.brandLight)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(PrayerFormatting.name(next.prayer))
                            .font(.prayerHero)
                        Text(PrayerFormatting.clock(next.time, in: clock.timeZone))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Countdown
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(PrayerFormatting.countdownLong(clock.secondsUntilNext))
                        .font(.countdown)
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                }

                // Progress bar
                countdownProgress(next: next)
            } else {
                Text("No upcoming prayer times")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    @ViewBuilder
    private func countdownProgress(next: (prayer: Prayer, time: Date)) -> some View {
        // Calculate progress: how far through the current waqt window we are
        if let waqt = clock.currentWaqt {
            let totalWindow = waqt.end.timeIntervalSince(clock.now) + clock.secondsUntilNext
            let progress = totalWindow > 0 ? 1.0 - (clock.secondsUntilNext / totalWindow) : 0
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.brand.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.brand)
                        .frame(width: geo.size.width * min(max(progress, 0), 1), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: Prayer Times List

    private var prayerTimesList: some View {
        VStack(spacing: 0) {
            ForEach(Array(clock.orderedToday.enumerated()), id: \.element.prayer) { index, entry in
                PrayerTimesCard(
                    prayer: entry.prayer,
                    time: entry.time,
                    timeZone: clock.timeZone,
                    isNext: clock.nextEvent?.prayer == entry.prayer,
                    isPast: entry.time < clock.now,
                    iqamahTime: clock.iqamahTime(for: entry.prayer, prayerTime: entry.time)
                )

                if index < clock.orderedToday.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: Stop Adhan

    private var stopAdhanButton: some View {
        Button {
            clock.stopAdhan()
        } label: {
            HStack {
                Image(systemName: "stop.circle.fill")
                Text("Stop Adhan")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: Method Summary

    private var methodSummary: some View {
        VStack(spacing: 4) {
            if let autoLabel = settings.autoMethodLabel {
                Text(autoLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(clock.methodName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if settings.isDetectingLocation {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Detecting location…")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
