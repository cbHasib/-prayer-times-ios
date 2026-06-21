import XCTest
@testable import PrayerKit

/// Verifies the "current prayer window" resolver that drives the time-left
/// countdown: the active prayer and its closing instant across every interval,
/// including the non-obligatory sunrise→Dhuhr gap, Isha spanning into the next
/// day's Fajr, and the after-midnight pre-Fajr stretch. Also the Ishraq helper.
final class CurrentWaqtTests: XCTestCase {

    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// A fixed instant on 2026-06-08 (`day` 0) or a following day, in UTC.
    private func at(_ hour: Int, _ minute: Int, day: Int = 0) -> Date {
        let comps = DateComponents(year: 2026, month: 6, day: 8 + day, hour: hour, minute: minute)
        return cal.date(from: comps)!
    }

    private func day(_ offset: Int) -> PrayerTimes {
        PrayerTimes(date: at(0, 0, day: offset), times: [
            .fajr: at(5, 0, day: offset),
            .sunrise: at(6, 30, day: offset),
            .dhuhr: at(12, 0, day: offset),
            .asr: at(15, 30, day: offset),
            .maghrib: at(18, 0, day: offset),
            .isha: at(19, 30, day: offset),
        ])
    }

    private lazy var today = day(0)
    private lazy var tomorrow = day(1)

    private func waqt(at now: Date) -> CurrentWaqt? {
        CurrentWaqt.resolve(at: now, today: today, tomorrow: tomorrow)
    }

    func testDuringFajrEndsAtSunrise() {
        let w = waqt(at: at(5, 30))
        XCTAssertEqual(w?.prayer, .fajr)
        XCTAssertEqual(w?.end, at(6, 30))
        XCTAssertEqual(w?.isObligatory, true)
    }

    func testSunriseToDhuhrIsNonObligatoryGap() {
        let w = waqt(at: at(9, 0))
        XCTAssertEqual(w?.prayer, .sunrise)
        XCTAssertEqual(w?.isObligatory, false)
        XCTAssertEqual(w?.end, at(12, 0))   // the gap closes at Dhuhr
    }

    func testDuringDhuhrEndsAtAsr() {
        let w = waqt(at: at(13, 0))
        XCTAssertEqual(w?.prayer, .dhuhr)
        XCTAssertEqual(w?.end, at(15, 30))
    }

    func testDuringAsrEndsAtMaghrib() {
        let w = waqt(at: at(16, 0))
        XCTAssertEqual(w?.prayer, .asr)
        XCTAssertEqual(w?.end, at(18, 0))
    }

    func testDuringMaghribEndsAtIsha() {
        let w = waqt(at: at(18, 30))
        XCTAssertEqual(w?.prayer, .maghrib)
        XCTAssertEqual(w?.end, at(19, 30))
    }

    func testDuringIshaEndsAtTomorrowFajr() {
        let w = waqt(at: at(21, 0))
        XCTAssertEqual(w?.prayer, .isha)
        XCTAssertEqual(w?.end, at(5, 0, day: 1))
    }

    func testAfterMidnightBeforeFajrStillIsha() {
        let w = waqt(at: at(2, 0))   // early hours, before today's Fajr
        XCTAssertEqual(w?.prayer, .isha)
        XCTAssertEqual(w?.end, at(5, 0))   // ends at today's Fajr
    }

    func testExactBoundaryBelongsToStartingPrayer() {
        // At the Asr instant the active window is Asr, not Dhuhr.
        let w = waqt(at: at(15, 30))
        XCTAssertEqual(w?.prayer, .asr)
        XCTAssertEqual(w?.end, at(18, 0))
    }

    func testIshraqIsSunrisePlusOffset() {
        XCTAssertEqual(today.ishraq(offsetMinutes: 15), at(6, 45))
        XCTAssertEqual(today.ishraq(offsetMinutes: 20), at(6, 50))
    }
}
