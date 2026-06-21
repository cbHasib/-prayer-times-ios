import SwiftUI
import PrayerKit

/// A single prayer time row in the prayer times list.
struct PrayerTimesCard: View {
    let prayer: Prayer
    let time: Date
    let timeZone: TimeZone
    let isNext: Bool
    let isPast: Bool
    let iqamahTime: Date?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: PrayerFormatting.icon(prayer))
                .font(.body.weight(.medium))
                .foregroundStyle(isNext ? Color.white : (isPast ? Color.secondary : Color.brand))
                .frame(width: 36, height: 36)
                .background(isNext ? Color.brand : Color.brand.opacity(isPast ? 0.05 : 0.1))
                .clipShape(Circle())

            // Name & optional iqamah
            VStack(alignment: .leading, spacing: 1) {
                Text(PrayerFormatting.name(prayer))
                    .font(.body.weight(isNext ? .semibold : .regular))
                    .foregroundStyle(isPast ? .secondary : .primary)

                if let iqamah = iqamahTime {
                    Text("Iqamah \(PrayerFormatting.clock(iqamah, in: timeZone))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Time
            Text(PrayerFormatting.clock(time, in: timeZone))
                .font(.body.weight(isNext ? .bold : .regular).monospacedDigit())
                .foregroundStyle(isPast ? .secondary : (isNext ? Color.brand : .primary))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isNext ? Color.brandLight : Color.clear)
        .animation(.easeInOut(duration: 0.3), value: isNext)
    }
}
