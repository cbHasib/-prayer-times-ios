import Foundation

/// Converts a target sun altitude (or Asr shadow factor) into a time offset from
/// solar noon, given latitude and declination. All times are hours; "before
/// noon" callers negate the returned half-arc. Polar cases where the sun never
/// reaches the angle return `nil`.
enum HourAngleCalc {

    /// Hours between solar noon and the moment the sun sits at `angle` degrees
    /// below the horizon (positive `angle` = below). `nil` when the altitude is
    /// never reached at this latitude/declination (polar day or night).
    static func hourAngle(altitudeBelowHorizon angle: Double,
                          latitude: Double,
                          declination: Double) -> Double? {
        let numerator = -DegreeMath.sin(angle) - DegreeMath.sin(latitude) * DegreeMath.sin(declination)
        let denominator = DegreeMath.cos(latitude) * DegreeMath.cos(declination)
        let cosH = numerator / denominator
        guard cosH >= -1, cosH <= 1 else { return nil }
        return DegreeMath.acos(cosH) / 15
    }

    /// Hours from solar noon to Asr, for the given shadow factor (1 = Standard,
    /// 2 = Hanafi). The Asr altitude is derived from the noon shadow length.
    static func asrHourAngle(shadowFactor: Double,
                             latitude: Double,
                             declination: Double) -> Double? {
        // Sun altitude at Asr (above the horizon, so positive):
        //   α = acot(factor + tan(|lat − decl|)).
        let altitude = DegreeMath.acot(shadowFactor + DegreeMath.tan(abs(latitude - declination)))
        // The horizon formula takes depression below the horizon = −altitude.
        return hourAngle(altitudeBelowHorizon: -altitude, latitude: latitude, declination: declination)
    }
}
