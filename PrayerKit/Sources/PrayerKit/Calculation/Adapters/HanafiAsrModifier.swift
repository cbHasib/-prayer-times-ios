import Foundation

/// Madhab is not a method — it is a modifier that overrides only the Asr shadow
/// factor on top of any official method. Wrapping `MWLAdapter` in this yields
/// "MWL, Hanafi Asr". Standard (Shafi/Maliki/Hanbali) Asr needs no wrapper.
public struct HanafiAsrModifier: CalculationMethodAdapter {
    public let base: any CalculationMethodAdapter

    public init(base: any CalculationMethodAdapter) {
        self.base = base
    }

    public var id: String { base.id + ".hanafi" }
    public var displayName: String { base.displayName + " (Hanafi)" }
    public var summary: String { base.summary + " Hanafi Asr (shadow ×2)." }

    public func resolve(for coordinates: Coordinates) -> CalculationParameters {
        var p = base.resolve(for: coordinates)
        p.asrShadowFactor = 2.0
        return p
    }
}
