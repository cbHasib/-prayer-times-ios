import Foundation

/// Egyptian General Authority of Survey. Fajr 19.5°, Isha 17.5°, shadow factor 1.
public struct EgyptianAdapter: CalculationMethodAdapter {
    public let id = "egyptian"
    public let displayName = "Egyptian General Authority of Survey"
    public let summary = "Fajr 19.5°, Isha 17.5°."

    public init() {}

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        CalculationParameters(
            fajrAngle: 19.5,
            ishaAngle: 17.5,
            asrShadowFactor: 1.0,
            highLatitudeRule: .angleBased
        )
    }
}
