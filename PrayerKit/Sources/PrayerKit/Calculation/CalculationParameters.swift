import Foundation

/// The complete numeric contract the engine consumes. Everything Islam-specific
/// (twilight angles, shadow factors, method offsets) is expressed here so the
/// engine itself stays a pure astronomical calculator. Adapters produce these.
public struct CalculationParameters: Sendable, Equatable, Codable, Hashable {
    /// Sun depression below the horizon for Fajr, in degrees (e.g. 18.0).
    public var fajrAngle: Double

    /// Sun depression below the horizon for Isha, in degrees. `nil` when the
    /// method defines Isha as a fixed offset after Maghrib instead.
    public var ishaAngle: Double?

    /// Fixed minutes after Maghrib for Isha (e.g. Umm al-Qura = 90). Mutually
    /// exclusive with `ishaAngle`; when both are set, the fixed offset wins.
    public var ishaFixedMinutes: Int?

    /// Apparent solar altitude at sunrise/sunset, in degrees (negative = below
    /// horizon). Standard atmospheric refraction is −0.833; Diyanet uses −1.9.
    public var sunriseAngle: Double

    /// Asr shadow length factor: 1.0 = Shafi/Maliki/Hanbali/Diyanet, 2.0 = Hanafi.
    public var asrShadowFactor: Double

    /// Minutes added to solar transit for Dhuhr (Diyanet ihtiyat = +5, others 0).
    public var dhuhrOffsetMinutes: Int

    /// Minutes added to the computed Asr time (Diyanet = +4, others 0).
    public var asrOffsetMinutes: Int

    /// Signed per-prayer fine-tuning in minutes, applied last. Absent keys = 0.
    public var manualOffsets: [Prayer: Int]

    /// High-latitude resolution strategy for Fajr/Isha.
    public var highLatitudeRule: HighLatitudeRule

    public init(
        fajrAngle: Double,
        ishaAngle: Double? = nil,
        ishaFixedMinutes: Int? = nil,
        sunriseAngle: Double = -0.833,
        asrShadowFactor: Double = 1.0,
        dhuhrOffsetMinutes: Int = 0,
        asrOffsetMinutes: Int = 0,
        manualOffsets: [Prayer: Int] = [:],
        highLatitudeRule: HighLatitudeRule = .none
    ) {
        self.fajrAngle = fajrAngle
        self.ishaAngle = ishaAngle
        self.ishaFixedMinutes = ishaFixedMinutes
        self.sunriseAngle = sunriseAngle
        self.asrShadowFactor = asrShadowFactor
        self.dhuhrOffsetMinutes = dhuhrOffsetMinutes
        self.asrOffsetMinutes = asrOffsetMinutes
        self.manualOffsets = manualOffsets
        self.highLatitudeRule = highLatitudeRule
    }
}
