import Foundation

/// Post-processing that clamps Fajr/Isha to a portion of the night when the
/// pure angle calculation produces times that are too close to midnight (or
/// undefined entirely) at high latitudes. Operates on local clock-hour values;
/// because it works on *differences* from sunrise/sunset it is invariant to the
/// timezone offset applied later.
extension HighLatitudeRule {

    /// Fraction of the night allotted to the twilight phase for `angle`.
    func nightPortion(angle: Double) -> Double {
        switch self {
        case .automatic, .none: return 0
        case .middleOfNight: return 1.0 / 2.0
        case .seventhOfNight: return 1.0 / 7.0
        case .angleBased: return angle / 60.0
        }
    }

    /// Clamp `time` so it is no further than the allotted night portion from
    /// `base` (sunrise for Fajr, sunset for Isha). `before == true` for events
    /// that precede `base` (Fajr). A `NaN` input (angle never reached) is forced
    /// to the clamp boundary.
    func clamp(_ time: Double, base: Double, angle: Double, night: Double, before: Bool) -> Double {
        guard self != .none, self != .automatic else { return time }
        let portion = nightPortion(angle: angle) * night
        let diff = before ? base - time : time - base
        if time.isNaN || diff > portion {
            return before ? base - portion : base + portion
        }
        return time
    }
}
