import Foundation

/// Islamic Society of North America. Fajr 15°, Isha 15°, shadow factor 1. Common
/// across the US and Canada.
public struct ISNAAdapter: CalculationMethodAdapter {
    public let id = "isna"
    public let displayName = "Islamic Society of North America"
    public let summary = "Fajr 15°, Isha 15°. North America."

    public init() {}

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        CalculationParameters(
            fajrAngle: 15.0,
            ishaAngle: 15.0,
            asrShadowFactor: 1.0,
            highLatitudeRule: .angleBased
        )
    }
}
