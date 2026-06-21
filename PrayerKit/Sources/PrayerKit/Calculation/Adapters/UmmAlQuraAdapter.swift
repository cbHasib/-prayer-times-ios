import Foundation

/// Umm al-Qura University, Makkah. Fajr 18.5°, and Isha as a fixed 90 minutes
/// after Maghrib (not an angle). Standard across Saudi Arabia.
public struct UmmAlQuraAdapter: CalculationMethodAdapter {
    public let id = "ummalqura"
    public let displayName = "Umm al-Qura (Makkah)"
    public let summary = "Fajr 18.5°, Isha = Maghrib + 90 min."

    public init() {}

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        CalculationParameters(
            fajrAngle: 18.5,
            ishaAngle: nil,
            ishaFixedMinutes: 90,
            asrShadowFactor: 1.0,
            highLatitudeRule: .none
        )
    }
}
