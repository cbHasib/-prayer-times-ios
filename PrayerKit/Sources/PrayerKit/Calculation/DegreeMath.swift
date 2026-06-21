import Foundation

/// Trigonometry in degrees plus angle/hour normalization. The classical prayer
/// time formulas are all stated in degrees, so working in radians everywhere
/// just adds conversion noise and rounding error. Kept internal to PrayerKit.
enum DegreeMath {
    @inline(__always) static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    @inline(__always) static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

    @inline(__always) static func sin(_ d: Double) -> Double { Foundation.sin(radians(d)) }
    @inline(__always) static func cos(_ d: Double) -> Double { Foundation.cos(radians(d)) }
    @inline(__always) static func tan(_ d: Double) -> Double { Foundation.tan(radians(d)) }

    @inline(__always) static func asin(_ x: Double) -> Double { degrees(Foundation.asin(x)) }
    @inline(__always) static func acos(_ x: Double) -> Double { degrees(Foundation.acos(x)) }
    @inline(__always) static func atan2(_ y: Double, _ x: Double) -> Double { degrees(Foundation.atan2(y, x)) }

    /// arccot in degrees.
    @inline(__always) static func acot(_ x: Double) -> Double { degrees(Foundation.atan2(1, x)) }

    /// Wrap an angle into [0, 360).
    @inline(__always) static func fixAngle(_ a: Double) -> Double { fix(a, 360) }

    /// Wrap an hour value into [0, 24).
    @inline(__always) static func fixHour(_ h: Double) -> Double { fix(h, 24) }

    @inline(__always) static func fix(_ value: Double, _ mod: Double) -> Double {
        let r = value - mod * (value / mod).rounded(.down)
        return r < 0 ? r + mod : r
    }
}
