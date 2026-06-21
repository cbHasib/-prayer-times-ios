import Foundation

/// Fully user-supplied parameters. Backs the "Manual" method in settings and
/// doubles as the debugging tool (drive the engine with arbitrary angles,
/// offsets, and shadow factor). Carries its parameters verbatim.
public struct ManualAdapter: CalculationMethodAdapter {
    public let id = "manual"
    public let displayName = "Manual"
    public let summary = "User-supplied angles, shadow factor, and offsets."

    public let parameters: CalculationParameters

    public init(parameters: CalculationParameters) {
        self.parameters = parameters
    }

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        parameters
    }
}
