import Foundation

/// Türkiye Diyanet İşleri Başkanlığı. The validated reference method: Fajr 18°,
/// Isha 17°, a −1.9° sunrise/maghrib horizon, shadow factor 1, and the official
/// ihtiyat (precaution) offsets of +5 min on Dhuhr and +4 min on Asr.
/// Reproduces the official Diyanet tables to within ±1 minute (see §6.6).
public struct DiyanetAdapter: CalculationMethodAdapter {
    public let id = "diyanet"
    public let displayName = "Diyanet İşleri (Türkiye)"
    public let summary = "Fajr 18°, Isha 17°, horizon −1.9°, +5 min Dhuhr, +4 min Asr."

    public init() {}

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        CalculationParameters(
            fajrAngle: 18.0,
            ishaAngle: 17.0,
            sunriseAngle: -1.9,
            asrShadowFactor: 1.0,
            dhuhrOffsetMinutes: 5,
            asrOffsetMinutes: 4,
            highLatitudeRule: .none
        )
    }
}
