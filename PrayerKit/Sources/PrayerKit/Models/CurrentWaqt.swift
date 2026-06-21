import Foundation

/// The prayer window that is currently in progress, used for the "time left in
/// the current prayer" countdown (e.g. "Asr · 40m left") as opposed to the
/// "next prayer in X" countdown.
///
/// Each obligatory prayer's window runs until the next event in the day; Isha
/// runs until the following day's Fajr. The interval between `sunrise` and
/// `dhuhr` carries no obligatory prayer (it is the Duha/Ishraq period) — it is
/// represented with `prayer == .sunrise` and `isObligatory == false`, so callers
/// can fall back to a next-prayer display there.
public struct CurrentWaqt: Sendable, Equatable {
    /// The prayer whose window is active. `.sunrise` marks the post-sunrise gap
    /// (Duha/Ishraq), which has no obligatory prayer in progress.
    public let prayer: Prayer
    /// The instant this window closes (the start of the next event).
    public let end: Date

    public init(prayer: Prayer, end: Date) {
        self.prayer = prayer
        self.end = end
    }

    /// `false` during the sunrise→Dhuhr gap; `true` while an obligatory prayer's
    /// window is in progress.
    public var isObligatory: Bool { prayer.isObligatory }

    /// Resolve the window containing `now`, spanning the day boundary so that
    /// Isha (until the next Fajr) and the after-midnight pre-Fajr stretch both
    /// resolve correctly. Returns `nil` only when the required times are missing
    /// (e.g. a polar edge case left Fajr undefined).
    ///
    /// - Parameters:
    ///   - now: the current instant.
    ///   - today: the civil day's computed times.
    ///   - tomorrow: the next civil day's times (for Isha's end at the next Fajr).
    public static func resolve(at now: Date, today: PrayerTimes, tomorrow: PrayerTimes) -> CurrentWaqt? {
        // The day's boundaries in chronological order, each tagged with the
        // prayer whose window begins there.
        let order: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        let boundaries: [(prayer: Prayer, time: Date)] = order.compactMap { prayer in
            today[prayer].map { (prayer, $0) }
        }
        guard let firstFajr = today[.fajr] else { return nil }

        // Before today's Fajr we are still inside yesterday's Isha, which ends at
        // today's Fajr. (We don't need yesterday's times — only the window end.)
        if now < firstFajr {
            return CurrentWaqt(prayer: .isha, end: firstFajr)
        }

        // The last boundary at or before `now` owns the active window.
        guard let idx = boundaries.lastIndex(where: { $0.time <= now }) else { return nil }
        let active = boundaries[idx].prayer

        // The window ends at the next boundary, or — for Isha — at tomorrow's Fajr.
        let end: Date
        if idx + 1 < boundaries.count {
            end = boundaries[idx + 1].time
        } else {
            guard let nextFajr = tomorrow[.fajr] else { return nil }
            end = nextFajr
        }
        return CurrentWaqt(prayer: active, end: end)
    }
}

public extension PrayerTimes {
    /// Start of the Ishraq/Duha window: a fixed offset after sunrise (roughly the
    /// time the sun has risen "a spear's length" above the horizon). Ishraq is a
    /// voluntary prayer, so this is a derived display value, not one of the six
    /// computed `times`. Returns `nil` if sunrise is undefined.
    func ishraq(offsetMinutes: Int = 15) -> Date? {
        self[.sunrise].map { $0.addingTimeInterval(Double(offsetMinutes) * 60) }
    }
}
