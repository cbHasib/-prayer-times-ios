import Foundation

/// The computed absolute times for one calendar day at one location, in the
/// timezone the engine was asked to use.
public struct PrayerTimes: Sendable, Equatable {
    /// The calendar day these times belong to (midnight, in the engine timezone).
    public let date: Date

    /// Absolute instant for each prayer. All six keys are present unless a polar
    /// edge case leaves Fajr/Isha undefined under `HighLatitudeRule.none`.
    public let times: [Prayer: Date]

    public init(date: Date, times: [Prayer: Date]) {
        self.date = date
        self.times = times
    }

    public subscript(_ prayer: Prayer) -> Date? {
        times[prayer]
    }

    /// The next prayer strictly after `now`, scanning this day's times in
    /// chronological order. Returns `nil` if every time today is in the past
    /// (caller should then consult tomorrow's `PrayerTimes`).
    public func next(after now: Date) -> (prayer: Prayer, time: Date)? {
        times
            .filter { $0.value > now }
            .min { $0.value < $1.value }
            .map { (prayer: $0.key, time: $0.value) }
    }

    /// The most recent prayer at or before `now` today, or `nil` if `now`
    /// precedes the day's first time.
    public func current(at now: Date) -> (prayer: Prayer, time: Date)? {
        times
            .filter { $0.value <= now }
            .max { $0.value < $1.value }
            .map { (prayer: $0.key, time: $0.value) }
    }

    /// Times in chronological order, e.g. for rendering the panel list.
    public var ordered: [(prayer: Prayer, time: Date)] {
        times
            .map { (prayer: $0.key, time: $0.value) }
            .sorted { $0.time < $1.time }
    }
}
