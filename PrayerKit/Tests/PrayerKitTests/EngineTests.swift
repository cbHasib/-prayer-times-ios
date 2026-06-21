import XCTest
@testable import PrayerKit

/// Validates the astronomical core against independently verifiable data. The
/// Raleigh case anchors on NOAA / timeanddate.com sun figures (sunrise, sunset,
/// solar noon, and 18° astronomical twilight) plus a hand-computed Asr, none of
/// which depend on this engine. Agreement proves declination, equation of time,
/// and the hour-angle formula are correct; the Diyanet ±1-min table gate
/// (Appendix A) then only needs to exercise the method offsets on top.
final class EngineTests: XCTestCase {

    /// Raleigh, NC — 2015-07-12, (35.7750, −78.6336), MWL (Fajr 18°, Isha 17°),
    /// Shafi Asr, America/New_York (EDT, UTC−4). Reference values:
    /// • Sunrise 06:08, solar noon 13:20, sunset 20:32 — NOAA/timeanddate.
    /// • Fajr 18° = astronomical dawn ≈ 04:21 — timeanddate astronomical twilight.
    /// • Asr (Shafi) 17:09 — hand-computed: Asr altitude acot(1+tan|lat−decl|)
    ///   = 38.69°, hour angle 57.2° ⇒ 3h49m after noon.
    /// • Isha 17° ≈ 22:10, just before the 18° astronomical dusk (≈22:13).
    func testMWLReferenceRaleigh() {
        let tz = TZ.make("America/New_York")
        let coords = Coordinates(latitude: 35.7750, longitude: -78.6336)
        let times = PrayerTimeEngine.calculate(
            date: components(2015, 7, 12),
            coordinates: coords,
            params: MWLAdapter().resolve(for: coords),
            timeZone: tz
        )
        assertTime(times[.fajr], equals: "04:21", in: tz, tolerance: 3, "Fajr")
        assertTime(times[.sunrise], equals: "06:08", in: tz, tolerance: 2, "Sunrise")
        assertTime(times[.dhuhr], equals: "13:20", in: tz, tolerance: 2, "Dhuhr")
        assertTime(times[.asr], equals: "17:09", in: tz, tolerance: 2, "Asr")
        assertTime(times[.maghrib], equals: "20:32", in: tz, tolerance: 2, "Maghrib")
        assertTime(times[.isha], equals: "22:10", in: tz, tolerance: 3, "Isha")
    }

    /// Times must come out in strict chronological order on an ordinary day.
    func testChronologicalOrder() {
        let tz = TZ.make("Europe/Istanbul")
        let coords = Coordinates(latitude: 41.0082, longitude: 28.9784)
        let t = PrayerTimeEngine.calculate(
            date: components(2024, 3, 21),
            coordinates: coords,
            params: DiyanetAdapter().resolve(for: coords),
            timeZone: tz
        )
        let order: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        let dates = order.compactMap { t[$0] }
        XCTAssertEqual(dates.count, 6, "all six times present")
        for i in 1..<dates.count {
            XCTAssertLessThan(dates[i - 1], dates[i], "\(order[i-1]) should precede \(order[i])")
        }
    }

    /// The returned `date` is local midnight, and every time falls on that day.
    func testTimesFallOnRequestedDay() {
        let tz = TZ.make("Europe/Istanbul")
        let coords = Coordinates(latitude: 41.0082, longitude: 28.9784)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let t = PrayerTimeEngine.calculate(
            date: components(2024, 6, 1),
            coordinates: coords,
            params: DiyanetAdapter().resolve(for: coords),
            timeZone: tz
        )
        for (prayer, date) in t.times {
            XCTAssertTrue(cal.isDate(date, inSameDayAs: t.date), "\(prayer) on requested day")
        }
    }

    /// Hanafi Asr (shadow ×2) must fall later than Standard Asr, same day/place.
    func testHanafiAsrIsLater() {
        let tz = TZ.make("Asia/Karachi")
        let coords = Coordinates(latitude: 24.8607, longitude: 67.0011)
        let standard = PrayerTimeEngine.calculate(
            date: components(2024, 1, 15), coordinates: coords,
            params: KarachiAdapter().resolve(for: coords), timeZone: tz
        )
        let hanafi = PrayerTimeEngine.calculate(
            date: components(2024, 1, 15), coordinates: coords,
            params: HanafiAsrModifier(base: KarachiAdapter()).resolve(for: coords), timeZone: tz
        )
        XCTAssertGreaterThan(hanafi[.asr]!, standard[.asr]!, "Hanafi Asr is later")
    }

    /// Umm al-Qura defines Isha as exactly Maghrib + 90 minutes.
    func testUmmAlQuraFixedIsha() {
        let tz = TZ.make("Asia/Riyadh")
        let coords = Coordinates(latitude: 21.4225, longitude: 39.8262)   // Makkah
        let t = PrayerTimeEngine.calculate(
            date: components(2024, 5, 10), coordinates: coords,
            params: UmmAlQuraAdapter().resolve(for: coords), timeZone: tz
        )
        let gap = t[.isha]!.timeIntervalSince(t[.maghrib]!)
        XCTAssertEqual(gap, 90 * 60, accuracy: 1, "Isha is Maghrib + 90 min")
    }

    /// Diyanet ihtiyat: Dhuhr is +5 min and Asr +4 min versus the same method
    /// with offsets zeroed. Isolates the offset handling from the astronomy.
    func testDiyanetIhtiyatOffsets() {
        let tz = TZ.make("Europe/Istanbul")
        let coords = Coordinates(latitude: 41.0082, longitude: 28.9784)
        let date = components(2024, 9, 1)

        var noOffset = DiyanetAdapter().resolve(for: coords)
        noOffset.dhuhrOffsetMinutes = 0
        noOffset.asrOffsetMinutes = 0

        let withOffset = PrayerTimeEngine.calculate(date: date, coordinates: coords,
            params: DiyanetAdapter().resolve(for: coords), timeZone: tz)
        let baseline = PrayerTimeEngine.calculate(date: date, coordinates: coords,
            params: noOffset, timeZone: tz)

        XCTAssertEqual(withOffset[.dhuhr]!.timeIntervalSince(baseline[.dhuhr]!), 5 * 60, accuracy: 1)
        XCTAssertEqual(withOffset[.asr]!.timeIntervalSince(baseline[.asr]!), 4 * 60, accuracy: 1)
    }

    /// Signed per-prayer manual offsets are applied last.
    func testManualOffsets() {
        let tz = TZ.make("Europe/London")
        let coords = Coordinates(latitude: 51.5074, longitude: -0.1278)
        let date = components(2024, 4, 1)

        var params = MWLAdapter().resolve(for: coords)
        let baseline = PrayerTimeEngine.calculate(date: date, coordinates: coords, params: params, timeZone: tz)
        params.manualOffsets = [.fajr: -3, .isha: 7]
        let tuned = PrayerTimeEngine.calculate(date: date, coordinates: coords, params: params, timeZone: tz)

        XCTAssertEqual(tuned[.fajr]!.timeIntervalSince(baseline[.fajr]!), -3 * 60, accuracy: 1)
        XCTAssertEqual(tuned[.isha]!.timeIntervalSince(baseline[.isha]!), 7 * 60, accuracy: 1)
        XCTAssertEqual(tuned[.dhuhr]!, baseline[.dhuhr]!, "untouched prayers unchanged")
    }

    /// High latitudes in midsummer: with `.none` the angle may be unreachable
    /// (nil), but `.angleBased` must always yield a Fajr and Isha.
    func testHighLatitudeRuleFillsMissingTimes() {
        let tz = TZ.make("Europe/Oslo")
        let coords = Coordinates(latitude: 59.9139, longitude: 10.7522)   // Oslo
        let date = components(2024, 6, 21)                                  // solstice

        var none = MWLAdapter().resolve(for: coords)
        none.highLatitudeRule = .none
        let raw = PrayerTimeEngine.calculate(date: date, coordinates: coords, params: none, timeZone: tz)

        var angle = MWLAdapter().resolve(for: coords)
        angle.highLatitudeRule = .angleBased
        let adjusted = PrayerTimeEngine.calculate(date: date, coordinates: coords, params: angle, timeZone: tz)

        XCTAssertNil(raw[.fajr], "no true astronomical Fajr at Oslo on the solstice")
        XCTAssertNotNil(adjusted[.fajr], "angle-based rule supplies a Fajr")
        XCTAssertNotNil(adjusted[.isha], "angle-based rule supplies an Isha")
        XCTAssertLessThan(adjusted[.fajr]!, adjusted[.sunrise]!, "Fajr before sunrise")
    }

    /// Kraków (50°N) in June: the sun grazes ~17.4° depression, so MWL's 18° Fajr
    /// never happens and its 17° Isha collapses to ~solar-midnight under `.none`.
    /// MWL's shipped `.angleBased` rule must produce a sane pre-dawn Fajr and a
    /// pre-midnight Isha that agree with reference tables (~2:1x AM / ~10:5x PM).
    func testKrakowJuneAngleBasedFajrAndIsha() {
        let tz = TZ.make("Europe/Warsaw")
        let coords = Coordinates(latitude: 50.0532, longitude: 19.9443)
        let date = components(2026, 6, 5)
        let cal = { () -> Calendar in var c = Calendar(identifier: .gregorian); c.timeZone = tz; return c }()

        // MWL ships .angleBased — exactly what SettingsStore keeps under `.automatic`.
        let params = MWLAdapter().resolve(for: coords)
        XCTAssertEqual(params.highLatitudeRule, .angleBased, "MWL must recommend angle-based at high latitude")
        let t = PrayerTimeEngine.calculate(date: date, coordinates: coords, params: params, timeZone: tz)

        let fajr = try! XCTUnwrap(t[.fajr], "angle-based supplies a Fajr")
        let isha = try! XCTUnwrap(t[.isha], "angle-based supplies an Isha")
        XCTAssertLessThan(fajr, t[.sunrise]!, "Fajr before sunrise")
        XCTAssertLessThan(t[.maghrib]!, isha, "Isha after Maghrib")

        // Reference (aladhan MWL): Fajr ~2:13 AM, Isha ~10:57 PM. Allow ±15 min.
        let fajrMin = cal.component(.hour, from: fajr) * 60 + cal.component(.minute, from: fajr)
        let ishaMin = cal.component(.hour, from: isha) * 60 + cal.component(.minute, from: isha)
        XCTAssertEqual(fajrMin, 2 * 60 + 13, accuracy: 15, "Fajr near 2:13 AM")
        XCTAssertEqual(ishaMin, 22 * 60 + 57, accuracy: 15, "Isha near 10:57 PM")
        XCTAssertLessThan(isha, t[.maghrib]!.addingTimeInterval(4 * 3600), "Isha well before midnight, not pinned to solar midnight")
    }
}
