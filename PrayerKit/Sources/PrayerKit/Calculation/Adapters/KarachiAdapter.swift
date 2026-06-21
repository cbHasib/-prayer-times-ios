import Foundation

/// University of Islamic Sciences, Karachi. Fajr 18°, Isha 18°, shadow factor 1.
/// Common across Pakistan, India, Bangladesh, and Afghanistan.
public struct KarachiAdapter: CalculationMethodAdapter {
    public let id = "karachi"
    public let displayName = "University of Islamic Sciences, Karachi"
    public let summary = "Fajr 18°, Isha 18°."

    public init() {}

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        CalculationParameters(
            fajrAngle: 18.0,
            ishaAngle: 18.0,
            asrShadowFactor: 1.0,
            highLatitudeRule: .angleBased
        )
    }
}
