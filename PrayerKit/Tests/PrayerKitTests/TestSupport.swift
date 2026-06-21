import Foundation
import XCTest
@testable import PrayerKit

/// Shared helpers for reading computed times back as "HH:mm" in a given zone.
enum TZ {
    static func make(_ id: String) -> TimeZone {
        guard let tz = TimeZone(identifier: id) else {
            fatalError("Unknown timezone identifier: \(id)")
        }
        return tz
    }
}

extension Date {
    /// Minutes-since-midnight rendering of this instant in `timeZone`.
    func minutesOfDay(in timeZone: TimeZone) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let c = cal.dateComponents([.hour, .minute], from: self)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    func hhmm(in timeZone: TimeZone) -> String {
        let m = minutesOfDay(in: timeZone)
        return String(format: "%02d:%02d", m / 60, m % 60)
    }
}

extension XCTestCase {
    /// Assert a computed prayer is within `tolerance` minutes of `expected`
    /// ("HH:mm"), reporting the human-readable delta on failure.
    func assertTime(
        _ time: Date?,
        equals expected: String,
        in timeZone: TimeZone,
        tolerance: Int = 1,
        _ label: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let time else {
            XCTFail("\(label): expected \(expected) but time was nil", file: file, line: line)
            return
        }
        let parts = expected.split(separator: ":").compactMap { Int($0) }
        let expectedMin = parts[0] * 60 + parts[1]
        let actualMin = time.minutesOfDay(in: timeZone)
        let delta = abs(actualMin - expectedMin)
        XCTAssertLessThanOrEqual(
            delta, tolerance,
            "\(label): expected \(expected), got \(time.hhmm(in: timeZone)) (Δ\(delta) min)",
            file: file, line: line
        )
    }

    func components(_ y: Int, _ m: Int, _ d: Int) -> DateComponents {
        DateComponents(year: y, month: m, day: d)
    }
}
