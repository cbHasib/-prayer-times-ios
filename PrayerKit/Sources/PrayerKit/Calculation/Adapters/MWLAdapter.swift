import Foundation

/// Muslim World League. Fajr 18°, Isha 17°, shadow factor 1. The sensible global
/// default and the fallback for unknown countries; uses the angle-based high-lat
/// rule which suits northern Europe.
public struct MWLAdapter: CalculationMethodAdapter {
    public let id = "mwl"
    public let displayName = "Muslim World League"
    public let summary = "Fajr 18°, Isha 17°. Global default."

    public init() {}

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        CalculationParameters(
            fajrAngle: 18.0,
            ishaAngle: 17.0,
            asrShadowFactor: 1.0,
            highLatitudeRule: .angleBased
        )
    }
}
