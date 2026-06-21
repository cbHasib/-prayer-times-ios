import Foundation

/// Low-precision solar position (declination + equation of time) good to well
/// under the ±1-minute accuracy this app requires. Based on the U.S. Naval
/// Observatory "Approximate Solar Coordinates" algorithm, the same one used by
/// PrayTimes.org. Inputs and outputs are in degrees / hours.
enum SolarCalculator {

    struct Position {
        /// Sun declination, degrees.
        let declination: Double
        /// Equation of time, hours (apparent − mean solar time).
        let equationOfTime: Double
    }

    /// Solar position at the given Julian Date.
    static func position(julianDate jd: Double) -> Position {
        let d = jd - 2451545.0                                  // days since J2000.0
        let g = DegreeMath.fixAngle(357.529 + 0.98560028 * d)   // mean anomaly
        let q = DegreeMath.fixAngle(280.459 + 0.98564736 * d)   // mean longitude
        let l = DegreeMath.fixAngle(                            // apparent longitude
            q + 1.915 * DegreeMath.sin(g) + 0.020 * DegreeMath.sin(2 * g)
        )
        let e = 23.439 - 0.00000036 * d                         // obliquity of ecliptic

        let declination = DegreeMath.asin(DegreeMath.sin(e) * DegreeMath.sin(l))
        let rightAscension = DegreeMath.fixHour(
            DegreeMath.atan2(DegreeMath.cos(e) * DegreeMath.sin(l), DegreeMath.cos(l)) / 15
        )
        let equationOfTime = q / 15 - rightAscension
        return Position(declination: declination, equationOfTime: equationOfTime)
    }

    /// Julian Date for a Gregorian calendar day at 00:00 UTC.
    static func julianDate(year: Int, month: Int, day: Double) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = (Double(y) / 100).rounded(.down)
        let b = 2 - a + (a / 4).rounded(.down)
        return (365.25 * Double(y + 4716)).rounded(.down)
            + (30.6001 * Double(m + 1)).rounded(.down)
            + day + b - 1524.5
    }
}
