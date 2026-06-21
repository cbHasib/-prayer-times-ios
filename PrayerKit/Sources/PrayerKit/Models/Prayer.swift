import Foundation

/// The six daily events the app tracks. `sunrise` is included because it bounds
/// the Fajr window and is shown in the panel, but it is not an obligatory prayer
/// (no iqamah, no congregation).
public enum Prayer: String, CaseIterable, Codable, Sendable, Hashable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    /// The five obligatory prayers, excluding `sunrise`. Iqamah/congregation
    /// concepts apply only to these.
    public static let obligatory: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    /// `true` for the five obligatory prayers; `false` for `sunrise`.
    public var isObligatory: Bool { self != .sunrise }

    /// Stable ordering through the day, used for "next prayer" logic.
    public var dayOrder: Int {
        switch self {
        case .fajr: return 0
        case .sunrise: return 1
        case .dhuhr: return 2
        case .asr: return 3
        case .maghrib: return 4
        case .isha: return 5
        }
    }
}
