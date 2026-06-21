# CLAUDE.md

Guidance for working in this repository.

## What this is

**Prayer Times for iOS** — a native, free iOS app showing Islamic prayer times with configurable notifications, Adhan playback, pluggable calculation methods, localization, and Focus Mode. Adapted from the original [Prayer Times for macOS](https://github.com/tareq1988/prayer-times-macos) by Tareq Hasan.

## Layout

```
project.yml             # XcodeGen project definition (iOS app target)
PrayerTimes.xcodeproj   # GENERATED from project.yml — git-ignored, do not edit
PrayerKit/              # pure calculation core, a standalone SwiftPM package
  Sources/PrayerKit/Calculation/   # engine, solar math, adapters (no UI/IO)
  Sources/PrayerKit/Models/        # Prayer, PrayerTimes, AppSettings, …
  Tests/PrayerKitTests/            # 31 tests incl. the Diyanet ±1-min gate
PrayerTimesiOS/         # the iOS app target (SwiftUI)
  App/                             # PrayerClock, entry point, helpers
  Services/                        # SettingsStore, LocationService, AudioService, NotificationService
  Views/                           # HomeView, FocusOverlayView, OnboardingView
  Settings/                        # Settings View controllers
  Supporting/Info.plist            # App Info plist
  Resources/                       # Assets.xcassets, sounds
```

## Build, run, test

```bash
# Calculation core tests
cd PrayerKit && swift test

# Regenerate the Xcode project after editing project.yml or adding files
xcodegen generate

# Build the iOS app for the Simulator
xcodebuild -project PrayerTimes.xcodeproj -scheme PrayerTimesiOS -sdk iphonesimulator -configuration Debug build
```

## Key facts (non-obvious; verified)

- **Engine accuracy is proven.** Astronomy is cross-checked against independent NOAA/timeanddate sun data; the Diyanet adapter reproduces the official June-2026 tables (Ankara, Başakşehir, Arnavutköy) to ±1 minute for every row — the Appendix A hard gate (`DiyanetGoldenTableTests`).
- **Diyanet horizon is a flat −1.9°, with NO elevation term.** Adding a `0.0347·√elevation` dip correction over-lengthens the day at altitude and breaks the gate. Do not re-add it.
- **JAKIM (Malaysia)** uses Fajr **17.5°**, Isha 18°, plus *ihtiyati* safety minutes (Dhuhr +3, Asr +2, Maghrib +2, Isha +2).
- **Kemenag (Indonesia)** uses Fajr **20°**, Isha **18°**, plus *ihtiyati* minutes (Subuh +2, Dzuhur +3, Ashar +2, Maghrib +3, Isya +2).
- **Focus Mode Preview** is triggered via a non-overlapping SwiftUI sheet dismiss mechanism using `clock.pendingFocusPreview` in `HomeView` and `FocusModeSettingsView` to avoid sheet presentation errors.

## Conventions

- **Swift 6, strict concurrency** everywhere (`SWIFT_STRICT_CONCURRENCY=complete`, language mode 6). UI/clock types are `@MainActor`.
- Adding a source file to the app target? Just run `xcodegen generate`. No manual `.pbxproj` edits.
