# Prayer Times for iOS

A free, native, and premium iOS application for Islamic prayer times. Ported and adapted from the original [Prayer Times for macOS](https://github.com/tareq1988/prayer-times-macos) by Tareq Hasan.

---

**Prayer Times for iOS** is a lightweight, offline-first application that calculates Islamic prayer times (Salah / Namaz) locally, plays the full **Adhan (Azan)**, manages scheduled notifications, and provides a fullscreen immersive **Focus Mode** helper to encourage stepping away from the device to pray.

It is 100% private (no telemetry, no accounts, no ads, and no external API requests) and built natively in modern SwiftUI.

## Features

- **Immersive Today View** — Clear countdown to the next prayer, dynamic progress tracking, and today's five daily prayers listed with their Iqamah offsets.
- **Focus Mode Overlay** — Covers your screen with a peaceful brand gradient during prayer times as a quiet discipline aid to encourage stepping away to pray. Includes an optional emergency dismiss button and a simulated **10-second Focus Mode Preview** to test the overlay layout.
- **Core Calculation Engine** — Supports 10 calculation methods:
  - **Diyanet** (Turkey)
  - **JAKIM** (Malaysia)
  - **Kemenag** (Indonesia)
  - **Muslim World League**
  - **ISNA** (North America)
  - **Umm al-Qura** (Saudi Arabia)
  - **Egyptian General Authority**
  - **University of Islamic Sciences, Karachi** (Pakistan)
  - **Moonsighting Committee**
  - **Manual / Custom parameters**
- **Adhan & Notifications** — Scheduled local notifications with Makkah/Madinah full Adhan playback (via in-process audio bypasses) and custom shorter notification sound clips.
- **Location Auto-Detect** — Uses core location services or manually inputted coordinates.

## Architecture

```
PrayerKit/            Pure, UI-free Swift Package (calculation core + models)
  Sources/            Engine, solar math, and method adapters (fully unit tested)
PrayerTimesiOS/       SwiftUI iOS Application
  App/                PrayerClock, App Entry, Formatting
  Services/           AudioService, LocationService, NotificationService, SettingsStore
  Views/              HomeView, FocusOverlayView, OnboardingView
  Settings/           Calculation, Location, Notification, and Focus settings views
project.yml           XcodeGen project spec
```

## How to Build & Run

1. Make sure you have Xcode installed.
2. Install **XcodeGen**:
   ```sh
   brew install xcodegen
   ```
3. Generate the Xcode project:
   ```sh
   xcodegen
   ```
4. Open the generated `PrayerTimes.xcodeproj` in Xcode.
5. Select the **`PrayerTimesiOS`** target.
6. Build and run (`Cmd + R`) on the iOS Simulator or a physical device.

## Credits & License

- Ported to iOS by [Hasib](https://github.com/hasib/prayer-time-ios).
- Original macOS menu bar application created by [Tareq Hasan](https://github.com/tareq1988/prayer-times-macos).
- Licensed under the [MIT License](LICENSE).
