import Foundation

/// Moonsighting Committee Worldwide. Fajr 18°, Isha 18°.
///
/// Note: the canonical Moonsighting method applies a *seasonal* twilight
/// correction that depends on both latitude and day-of-year — which the current
/// `resolve(for:)` contract (location only) cannot express. This adapter uses
/// the committee's base angles with an angle-based high-latitude rule as a close
/// approximation. Full seasonal support requires extending the adapter contract
/// to receive the date and is tracked as a follow-up.
public struct MoonsightingCommitteeAdapter: CalculationMethodAdapter {
    public let id = "moonsighting"
    public let displayName = "Moonsighting Committee Worldwide"
    public let summary = "Fajr 18°, Isha 18° (seasonal approximation)."

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
