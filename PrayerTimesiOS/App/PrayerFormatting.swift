import Foundation
import PrayerKit

/// Presentation helpers for the app layer. Reused from the macOS version with
/// minor adaptations (removed macOS-only Focus Mode formatting).
enum PrayerFormatting {

    /// Localized display name for a prayer.
    static func name(_ prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return String(localized: "Fajr")
        case .sunrise: return String(localized: "Sunrise")
        case .dhuhr: return String(localized: "Dhuhr")
        case .asr: return String(localized: "Asr")
        case .maghrib: return String(localized: "Maghrib")
        case .isha: return String(localized: "Isha")
        }
    }

    /// SF Symbol representing each prayer's time of day.
    static func icon(_ prayer: Prayer) -> String {
        switch prayer {
        case .fajr: return "sunrise"
        case .sunrise: return "sun.horizon.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "cloud.sun.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }

    /// Short clock time (e.g. "13:08" / "1:08 PM") in the given timezone.
    static func clock(_ date: Date, in timeZone: TimeZone) -> String {
        var fmt = Date.FormatStyle(date: .omitted, time: .shortened)
        fmt.timeZone = timeZone
        return date.formatted(fmt)
    }

    /// Long date (e.g. "Monday, 2 June 2026") in the given timezone.
    static func longDate(_ date: Date, in timeZone: TimeZone) -> String {
        var fmt = Date.FormatStyle(date: .complete, time: .omitted)
        fmt.timeZone = timeZone
        return date.formatted(fmt)
    }

    /// Localized Hijri date (e.g. "22 Dhuʻl-Hijjah 1447 AH") from the Umm al-Qura
    /// calendar, with a whole-day `adjustment` applied.
    static func hijriDate(_ date: Date, in timeZone: TimeZone, adjustment: Int) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        let adjusted = gregorian.date(byAdding: .day, value: adjustment, to: date) ?? date

        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = timeZone
        let parts = hijri.dateComponents([.day, .month, .year], from: adjusted)
        guard let day = parts.day, let month = parts.month, let year = parts.year else { return "" }

        let monthName = hijriMonthFormatter.monthSymbols[month - 1]
        let dayString = plainNumberFormatter.string(from: day as NSNumber) ?? String(day)
        let yearString = plainNumberFormatter.string(from: year as NSNumber) ?? String(year)

        let era = String(localized: "AH", comment: "Hijri era suffix shown after the year")
        return "\(dayString) \(monthName) \(yearString) \(era)"
    }

    private static let hijriMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        return f
    }()

    private static let plainNumberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.usesGroupingSeparator = false
        return f
    }()

    /// Full H:MM:SS countdown for the highlighted next prayer.
    static func countdownLong(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    /// Compact relative countdown: "3h 25m", "25m", or "45s".
    static func shortCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(s)s"
    }

    // MARK: Settings enum names

    static func highLatitudeRuleName(_ rule: HighLatitudeRule) -> String {
        switch rule {
        case .automatic: return String(localized: "Automatic (recommended)")
        case .none: return String(localized: "None")
        case .middleOfNight: return String(localized: "Middle of the night")
        case .seventhOfNight: return String(localized: "One-seventh of the night")
        case .angleBased: return String(localized: "Angle-based")
        }
    }

    static func soundName(_ sound: NotificationSound) -> String {
        switch sound {
        case .none: return String(localized: "None")
        case .systemDefault: return String(localized: "Default")
        case .softChime: return String(localized: "Soft chime")
        case .takbir: return String(localized: "Takbir")
        case .adhanMakkah: return String(localized: "Adhan (Makkah)")
        case .adhanMadinah: return String(localized: "Adhan (Madinah)")
        }
    }
}
