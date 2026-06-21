import Foundation

/// Selectable sound for a notification slot. The `.adhan*` cases imply a *short*
/// notification clip (≤30 s, the UN sound cap) plus optional full-file playback
/// via `AVAudioPlayer` in the resident app (see §9).
public enum NotificationSound: String, Codable, Sendable, CaseIterable, Hashable {
    case none
    case systemDefault
    case softChime
    case takbir
    case adhanMakkah
    case adhanMadinah

    /// Whether this selection has an associated full-length Adhan file that the
    /// in-process audio path can play.
    public var hasFullAdhan: Bool {
        switch self {
        case .adhanMakkah, .adhanMadinah: return true
        default: return false
        }
    }

    /// Bundled short clip filename used for the `UNNotificationSound`, or `nil`
    /// for `.none`/`.systemDefault` (which map to no sound / the system default).
    public var notificationClipFileName: String? {
        switch self {
        case .none, .systemDefault: return nil
        case .softChime: return "soft-chime.caf"
        case .takbir: return "takbir.caf"
        case .adhanMakkah, .adhanMadinah: return "takbir.caf"
        }
    }

    /// Bundled full-length Adhan filename for the in-process player, if any.
    public var fullAdhanFileName: String? {
        switch self {
        case .adhanMakkah: return "adhan-makkah.m4a"
        case .adhanMadinah: return "adhan-madinah.m4a"
        default: return nil
        }
    }
}
