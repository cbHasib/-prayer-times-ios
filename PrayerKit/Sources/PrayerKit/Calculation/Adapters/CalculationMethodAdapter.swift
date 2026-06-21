import Foundation

/// A calculation method: translates a location into the numeric parameters the
/// engine consumes. Methods are pure value producers — no state, no I/O.
public protocol CalculationMethodAdapter: Identifiable, Sendable {
    /// Stable key used for persistence and the registry. Never localized.
    var id: String { get }
    /// Human-readable name for the UI (localized at the presentation layer).
    var displayName: String { get }
    /// One-line description of the method's provenance / parameters.
    var summary: String { get }
    /// Produce engine parameters for the given location.
    func resolve(for coordinates: Coordinates) -> CalculationParameters
}
