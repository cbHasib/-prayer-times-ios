# PrayerKit

The pure, UI-free calculation core shared by the Prayer Times menu bar app and
its widget (spec §5, §11). No UIKit/AppKit/SwiftUI, no I/O — fully unit testable.

## What's here (Milestone M1)

```
Sources/PrayerKit/
├── Calculation/
│   ├── PrayerTimeEngine.swift      // public entry point: calculate(...)
│   ├── SolarCalculator.swift       // declination + equation of time (USNO model)
│   ├── HourAngleCalc.swift         // depression-angle and Asr hour angles
│   ├── HighLatitudeRule.swift      // rule enum
│   ├── HighLatitudeAdjustment.swift// night-portion clamping for Fajr/Isha
│   ├── DegreeMath.swift            // degree-based trig + angle/hour wrapping
│   ├── CalculationParameters.swift // the engine's numeric contract
│   ├── Coordinates.swift
│   └── Adapters/                   // method → parameters (the only Islam-specific layer)
│       ├── CalculationMethodAdapter.swift
│       ├── DiyanetAdapter.swift  MWLAdapter.swift  ISNAAdapter.swift
│       ├── UmmAlQuraAdapter.swift  EgyptianAdapter.swift  KarachiAdapter.swift
│       ├── MoonsightingCommitteeAdapter.swift  ManualAdapter.swift
│       ├── HanafiAsrModifier.swift // madhab as a composable modifier
│       └── MethodRegistry.swift    // id ↔ adapter, country → method
└── Models/
    ├── Prayer.swift  PrayerTimes.swift
    ├── AppSettings.swift  NotificationSound.swift
```

## Design rule

The engine is a pure astronomical calculator. Every method-specific value
(twilight angles, shadow factor, ihtiyat offsets, high-latitude rule) is
expressed in `CalculationParameters`, produced by an adapter. Madhab is **not**
a method — `HanafiAsrModifier` wraps any adapter and overrides only the Asr
shadow factor.

## Tests

```
swift test
```

All tests pass. The astronomy is cross-checked against independent NOAA /
timeanddate.com sun data and a hand-computed Asr (see `EngineTests.swift`).

### Diyanet golden-table gate (Appendix A — PASSING)

`DiyanetGoldenTableTests` enforces the ±1-minute requirement against the
official Diyanet monthly tables (June 2026) for Ankara, Istanbul/Başakşehir, and
Istanbul/Arnavutköy. The Diyanet adapter reproduces **every one of the 6×31×3
rows within ±1 minute.** Data lives in
`Tests/PrayerKitTests/Resources/DiyanetGoldenTables.json`, generated from the raw
`data/diyanet/*.csv` files. `DiyanetCalibration` is a dev-only harness (skips
when the repo `data/` dir is absent) for re-tuning district coordinates if the
source tables change.

Two calibration findings worth recording:
- **No elevation term on the horizon dip.** Diyanet's −1.9° horizon (§6.6) is a
  flat validated constant. An earlier `0.0347·√elevation` correction
  over-lengthened the day at altitude (Ankara, 938 m: sunrise 6–7 min early) and
  broke the gate. The engine now uses the dip from `sunriseAngle` directly.
- District reference coordinates were calibrated against the tables (e.g.
  Başakşehir latitude 41.06, not the 41.09 district centroid).

## Notable known limitation

`MoonsightingCommitteeAdapter` uses the committee's base angles with an
angle-based high-latitude rule. The canonical seasonal twilight correction
depends on the date, which the location-only `resolve(for:)` contract cannot
express; full support needs a contract extension (tracked as a follow-up).
