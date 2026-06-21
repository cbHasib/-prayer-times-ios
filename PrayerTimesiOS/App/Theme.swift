import SwiftUI

extension Color {
    /// The app's brand green — a rich Islamic green used for accents.
    static let brand = Color(red: 0.18, green: 0.58, blue: 0.247)

    /// Lighter tint for backgrounds / highlights.
    static let brandLight = Color(red: 0.18, green: 0.58, blue: 0.247).opacity(0.12)

    /// Dark surface for cards in dark mode.
    static let cardBackground = Color(.secondarySystemGroupedBackground)
}

extension Font {
    /// The large countdown display font.
    static let countdown = Font.system(size: 48, weight: .bold, design: .rounded).monospacedDigit()

    /// Prayer name in the hero section.
    static let prayerHero = Font.system(size: 28, weight: .bold, design: .rounded)
}
