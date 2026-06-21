import Foundation

/// The pure calculation core. Given a civil date, a location, a fully-resolved
/// `CalculationParameters` (produced by an adapter), and a timezone, it returns
/// the six absolute prayer instants. No UI, no I/O, no Islam-specific constants
/// — every method-specific value arrives via `params`.
public enum PrayerTimeEngine {

    /// Compute the day's prayer times.
    ///
    /// - Parameters:
    ///   - date: Must contain `year`, `month`, `day`. Other fields ignored.
    ///   - coordinates: Latitude/longitude/elevation of the observer.
    ///   - params: Resolved twilight angles, shadow factor, offsets, high-lat rule.
    ///   - timeZone: The timezone the returned `Date`s and the calendar day use.
    public static func calculate(
        date: DateComponents,
        coordinates: Coordinates,
        params: CalculationParameters,
        timeZone: TimeZone
    ) -> PrayerTimes {
        guard let year = date.year, let month = date.month, let day = date.day else {
            return PrayerTimes(date: Date(timeIntervalSince1970: 0), times: [:])
        }

        let lat = coordinates.latitude
        let lng = coordinates.longitude
        let tz = Double(timeZone.secondsFromGMT(for: midnight(year, month, day, timeZone))) / 3600.0
        let jd0 = SolarCalculator.julianDate(year: year, month: month, day: Double(day))

        // Sunrise/sunset horizon dip (positive degrees below horizon).
        // `sunriseAngle` is stored as an altitude (negative below horizon), so
        // the dip is its negation. We deliberately do NOT add an elevation
        // term: the official Diyanet horizon (−1.9°, §6.6) is a flat validated
        // constant, and standard methods specify their dip (−0.833°) directly.
        // Adding 0.0347·√elevation here over-lengthened the day at altitude
        // (e.g. Ankara, 938 m), breaking the ±1-minute golden-table gate.
        let dip = -params.sunriseAngle

        // --- Iterate: each event's solar position is evaluated at its own
        // approximate time. Two passes from sensible seeds converge well within
        // a second of arc for these purposes. ---
        var h = RawHours(fajr: 5, sunrise: 6, dhuhr: 12, asr: 13, maghrib: 18, isha: 18)
        for _ in 0..<3 {
            h = computePass(
                guess: h, jd0: jd0, lat: lat, lng: lng, tz: tz, dip: dip, params: params
            )
        }

        // --- High-latitude adjustment (Fajr always; Isha only when angle-based). ---
        let rule = params.highLatitudeRule
        if rule != .none, !h.sunrise.isNaN, !h.maghrib.isNaN {
            let night = (24 - h.maghrib) + h.sunrise   // sunset → next sunrise
            h.fajr = rule.clamp(h.fajr, base: h.sunrise, angle: params.fajrAngle,
                                night: night, before: true)
            if let ishaAngle = params.ishaAngle {
                h.isha = rule.clamp(h.isha, base: h.maghrib, angle: ishaAngle,
                                    night: night, before: false)
            }
        }

        // --- Method offsets. ---
        h.dhuhr += Double(params.dhuhrOffsetMinutes) / 60.0
        h.asr += Double(params.asrOffsetMinutes) / 60.0

        // --- Fixed-offset Isha (e.g. Umm al-Qura: Maghrib + 90). ---
        if let fixed = params.ishaFixedMinutes {
            h.isha = h.maghrib + Double(fixed) / 60.0
        }

        // --- Per-prayer manual fine-tuning, applied last. ---
        func tuned(_ value: Double, _ prayer: Prayer) -> Double {
            value + Double(params.manualOffsets[prayer] ?? 0) / 60.0
        }

        let base = midnight(year, month, day, timeZone)
        func instant(_ hours: Double, _ prayer: Prayer) -> Date? {
            let v = tuned(hours, prayer)
            guard v.isFinite else { return nil }
            // Round to the nearest whole minute. Published prayer tables (Diyanet,
            // JAKIM e-Solat, …) are minute-granular and round rather than truncate;
            // returning the rounded instant keeps the displayed clock, the
            // notification fire time, and the countdown all on the same minute
            // boundary. Offsets are whole minutes, so this never changes the
            // spacing between two computed times.
            let minutes = (v * 60).rounded()
            return base.addingTimeInterval(minutes * 60)
        }

        var times: [Prayer: Date] = [:]
        times[.fajr] = instant(h.fajr, .fajr)
        times[.sunrise] = instant(h.sunrise, .sunrise)
        times[.dhuhr] = instant(h.dhuhr, .dhuhr)
        times[.asr] = instant(h.asr, .asr)
        times[.maghrib] = instant(h.maghrib, .maghrib)
        times[.isha] = instant(h.isha, .isha)

        return PrayerTimes(date: base, times: times)
    }

    // MARK: - Internals

    private struct RawHours {
        var fajr, sunrise, dhuhr, asr, maghrib, isha: Double
    }

    /// One refinement pass: recompute every event using the solar position at
    /// its current estimated time.
    private static func computePass(
        guess: RawHours, jd0: Double, lat: Double, lng: Double, tz: Double,
        dip: Double, params: CalculationParameters
    ) -> RawHours {
        // Local clock noon for an event whose solar position is sampled at `t`.
        func noon(at t: Double) -> Double {
            let pos = SolarCalculator.position(julianDate: jd0 + (t - tz) / 24)
            return 12 - lng / 15 - pos.equationOfTime + tz
        }
        func declination(at t: Double) -> Double {
            SolarCalculator.position(julianDate: jd0 + (t - tz) / 24).declination
        }
        // Time of an event at depression `angle`, `before` or after local noon.
        func angleTime(_ angle: Double, at t: Double, before: Bool) -> Double {
            let n = noon(at: t)
            guard let ha = HourAngleCalc.hourAngle(
                altitudeBelowHorizon: angle, latitude: lat, declination: declination(at: t)
            ) else { return .nan }
            return before ? n - ha : n + ha
        }

        let dhuhr = noon(at: guess.dhuhr)
        let sunrise = angleTime(dip, at: guess.sunrise, before: true)
        let maghrib = angleTime(dip, at: guess.maghrib, before: false)
        let fajr = angleTime(params.fajrAngle, at: guess.fajr, before: true)
        let isha: Double = {
            guard let ishaAngle = params.ishaAngle else { return guess.isha }
            return angleTime(ishaAngle, at: guess.isha, before: false)
        }()
        let asr: Double = {
            let n = noon(at: guess.asr)
            guard let ha = HourAngleCalc.asrHourAngle(
                shadowFactor: params.asrShadowFactor, latitude: lat,
                declination: declination(at: guess.asr)
            ) else { return .nan }
            return n + ha
        }()

        return RawHours(fajr: fajr, sunrise: sunrise, dhuhr: dhuhr,
                        asr: asr, maghrib: maghrib, isha: isha)
    }

    /// Midnight (00:00) of the civil date in `timeZone`.
    private static func midnight(_ year: Int, _ month: Int, _ day: Int, _ timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps) ?? Date(timeIntervalSince1970: 0)
    }
}
