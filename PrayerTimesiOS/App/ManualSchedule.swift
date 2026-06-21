import Foundation
import PrayerKit

/// The fixed-schedule overlay for Manual time-source mode.
struct ManualSchedule: Equatable {
    var jamaatMinutes: [Prayer: Int]
    var azanBeforeJamaat: Int
    var keepWaqt: Bool

    func applied(to base: PrayerTimes, day: Date, timeZone: TimeZone) -> PrayerTimes {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let midnight = cal.startOfDay(for: day)
        var times = base.times
        for prayer in Prayer.obligatory {
            guard let minutes = jamaatMinutes[prayer] else { continue }
            times[prayer] = midnight.addingTimeInterval(TimeInterval(minutes) * 60)
        }
        return PrayerTimes(date: base.date, times: times)
    }
}
