import Foundation
import AVFoundation
import UIKit
import Observation
import OSLog
import PrayerKit

/// Plays the full Adhan in-process. Adapted from macOS: replaced `AppKit`/`NSSound`
/// with `UIKit`/`AVAudioSession`. Configures the audio session for playback so
/// Adhan plays even when the device is on silent mode (respecting user preference).
@MainActor
@Observable
final class AudioService: NSObject, AVAudioPlayerDelegate {
    private(set) var isPlaying = false

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private let log = Logger(subsystem: "co.hasib.prayertimes.ios", category: "audio")

    /// Play the full Adhan associated with `sound` (Makkah/Madinah).
    func playFullAdhan(_ sound: NotificationSound) {
        guard let fileName = sound.fullAdhanFileName else { return }
        guard let url = Self.bundleURL(for: fileName) else {
            log.warning("Full Adhan file not bundled: \(fileName, privacy: .public)")
            return
        }
        play(url)
    }

    /// Play a preview for the settings sound pickers.
    func preview(_ sound: NotificationSound) {
        switch sound {
        case .none:
            return
        case .systemDefault:
            // On iOS, play a short haptic/system sound as a preview
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return
        default:
            break
        }
        guard let fileName = sound.fullAdhanFileName ?? sound.notificationClipFileName else {
            return
        }
        guard let url = Self.bundleURL(for: fileName) else {
            log.warning("Preview file not bundled: \(fileName, privacy: .public)")
            return
        }
        play(url)
    }

    /// Play the short alert clip for `sound` in-process at prayer time.
    func playClip(_ sound: NotificationSound) {
        guard let fileName = sound.notificationClipFileName,
              let url = Self.bundleURL(for: fileName) else { return }
        play(url)
    }

    /// Stop any in-progress playback.
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        deactivateSession()
    }

    // MARK: AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.deactivateSession()
        }
    }

    // MARK: Helpers

    private func play(_ url: URL) {
        stop()
        configureSession()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            self.player = player
            isPlaying = true
        } catch {
            log.error("Failed to play \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
            isPlaying = false
        }
    }

    /// Configure the audio session for Adhan playback: plays over other audio,
    /// respects the ring/silent switch by default, and can be heard even with
    /// the device locked.
    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            log.error("Audio session config failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Locate a bundled audio file by name, checking Adhan/Sounds subdirectories.
    private static func bundleURL(for fileName: String) -> URL? {
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        let subdirs: [String?] = ["Adhan", "Sounds", nil]
        for subdir in subdirs {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                return url
            }
        }
        return nil
    }
}
