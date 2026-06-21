# Handoff: Prayer Time — Settings & Menu-bar Panel Redesign

## Overview
This package redesigns the **Prayer Time** macOS app's preferences window and adds a redesigned
menu-bar dropdown panel. It keeps the existing five-tab toolbar structure (General, Location & Time,
Calculation, Notifications, Focus Mode) but modernizes it to current macOS (System Settings–style
inset-grouped rows), **reorganizes the Notifications tab** so per-prayer settings are no longer long
repeated blocks, and **adds a new "Manual (fixed)" time source to the Calculation tab** for regions
where the mosque announces fixed jamaat times (e.g. Bangladesh) and the azan fires a set number of
minutes before.

## About the Design Files
The files in this bundle are **design references created in HTML/CSS/React** — a clickable prototype
showing the intended look and behavior. They are **not** production code to copy. The task is to
**recreate these designs in the existing Swift macOS codebase** (SwiftUI and/or AppKit) using its
established patterns:
- The settings window should remain a toolbar-style preferences window (`Settings`/`TabView(.tabBarStyle)`
  in SwiftUI, or an `NSToolbar`-backed `NSTabViewController` in AppKit).
- The menu-bar panel should be an `NSStatusItem` + `NSPopover` (or a SwiftUI `MenuBarExtra` with
  `.menuBarExtraStyle(.window)`).
- Use native controls (`Toggle`, `Picker`/pop-up button, `Stepper`, segmented `Picker`) — do **not**
  reimplement the custom HTML controls. The HTML versions only exist because the browser has no native
  macOS widgets.

## Fidelity
**High-fidelity.** Colors, typography, spacing, grouping, and interactions are final. Match them with
native macOS materials and the system accent color rather than hard-coding where a system value exists
(see Design Tokens).

---

## Screens / Views

### Window chrome (all tabs)
- Standard macOS titlebar; the centered title reflects the active tab name.
- A toolbar of 5 equal-width tab items below the titlebar, each an icon (22pt) above an 11.5pt label.
  Active tab: SF-symbol + label tint to accent, with a subtle accent-tinted rounded background.
- Content area: white background, ~18–22pt padding. Sections are: a bold 13pt header, then one or more
  **inset grouped cards** (light gray `#f4f4f6`, 9pt corner radius) containing rows. Optional 11.5pt
  gray caption below a group.
- Row: min-height 38pt (32pt in "compact" density), 13.5pt label on the left, control on the right,
  hairline separators between rows (inset from the left). Rows may carry a leading 17–22pt icon and a
  secondary 11.5pt gray sub-label under the main label.

SF Symbol mapping for tabs (use these or closest equivalents):
`gearshape` (General), `location.north.line` / `paperplane` (Location & Time), `moon` (Calculation),
`bell` (Notifications), `eye.slash` (Focus Mode).

### Tab 1 — General
Sections and controls:
- **Startup** → "Launch at login" (Toggle).
- **Menu bar** → "Label style" (pop-up: Icon only / Icon + countdown / Icon + name + countdown /
  Name + time); "Countdown shows" (pop-up: Next prayer / Next obligatory prayer / Time remaining only).
- **Panel** → "Show Ishraq time" (Toggle); "Show Hijri date" (Toggle).
- **Language** → "Language" (pop-up: English / Türkçe / العربية / Bahasa / বাংলা / Français).
  Caption: "Changing the language relaunches the app."
- **Updates** → "Check for updates automatically" (Toggle).

### Tab 2 — Location & Time
- **Location** → "Mode" segmented control (Automatic / Manual).
  - Automatic: a "Detect my location" push button; Latitude/Longitude/Elevation shown as read-only values.
  - Manual: Latitude / Longitude / Elevation become editable text fields.
- **Time zone** → "Time zone" segmented control (Follow system / Pick explicitly). When "Pick explicitly",
  reveal a "Zone" pop-up (IANA zones).
- **Hijri date** → "Day adjustment" Stepper (range −2…+2, label "+1 day", "0 days", etc.);
  "Today" read-only value (e.g. `23 Dhu'l-Hijjah 1447 AH`). Caption explaining Umm al-Qura + moon-sighting.

### Tab 3 — Calculation  ⭐ (one of two key changes)
- **Source** → "Time source" segmented control (**Calculated** / **Manual (fixed)**). The caption changes
  with the selection. This selection swaps the rest of the tab between two states:

  **Calculated state** (existing behavior, cleaned up):
  - **Method** group: "Calculation method" (pop-up: Diyanet İşleri (Türkiye), Muslim World League,
    Umm al-Qura, Egyptian General Authority, Karachi (Hanafi), ISNA, Moonsighting Committee);
    "Asr (madhab)" (pop-up: Standard (Shafiʿi) / Hanafi); "High-latitude rule" (pop-up: Automatic
    (recommended) / Middle of the night / One-seventh of night / Angle-based).
  - **Automation** group: "Auto-detect method from location" (Toggle); caption shows the auto-picked method.

  **Manual (fixed) state** (NEW — for fixed mosque jamaat schedules):
  - **Azan timing** group:
    - "Azan before jamaat" Stepper (0…60; label "At jamaat" at 0, otherwise "N min before"). This is the
      global offset.
    - "Follow waqt for Sunrise & windows" (Toggle) — keep astronomical times for non-jamaat events.
    - Caption: "The azan reminder fires this many minutes before the jamaat time set below."
  - **Jamaat schedule** group: one row per **obligatory** prayer (Fajr, Dhuhr, Asr, Maghrib, Isha — no
    Sunrise). Each row: leading prayer icon + name; on the right a small gray **azan chip** showing the
    computed azan time, the word "jamaat", and an editable **time field** for the jamaat time.
    - The azan chip = `jamaatTime − azanBefore`, formatted `azan HH:mm`, wrapping past midnight.
      Example: jamaat `05:00`, offset `15` → chip reads `azan 04:45`.
  - An "Import weekly timetable" row with an "Import…" button (CSV / mosque schedule). *Optional / can be
    stubbed; include the row but the importer itself is out of scope for the first pass.*

  **Data model note:** Manual mode means the app should source the 5 obligatory prayer times from the
  user-entered `jamaat[prayerKey]` values rather than the astronomical calculation, and schedule the
  azan notification at `jamaat − azanBefore`. Per-prayer azan-offset overrides are a reasonable future
  extension (the global offset covers the primary use case).

### Tab 4 — Notifications  ⭐ (the other key change — was a long list of repeated blocks)
Reorganized into three parts so per-prayer settings stop repeating the same five fields:
- **Master** group: "Enable notifications" (Toggle) + a "Send a sample notification" push button.
- **Defaults** group (applies to *every* prayer unless overridden): "Default sound" (pop-up + a small
  play/preview button), "Play full Adhan audio" (Toggle), "Early reminder" (pop-up: Off / 5 / 10 / 15 /
  30 min before), "Iqamah / jamaat offset" (Stepper 0…45; "Off" at 0). Caption: "Applied to every prayer.
  Set a prayer's own values below to override."
- **Per prayer** section — a compact control. Two layouts were prototyped (a Tweaks toggle switches them);
  **ship the Matrix layout** as the primary:
  - **Matrix**: a table with column headers **Notify / Adhan / Remind**. One row per prayer
    (Fajr, Sunrise, Ishraq excluded? — see list below), each with a leading icon + name and small
    switches under each column. A trailing "sliders" disclosure button expands an inline **override
    drawer** for that prayer (Sound, Play full Adhan, Early reminder, Iqamah/jamaat offset). Sunrise has
    only Notify + Remind (no Adhan — shown as "—").
  - **Stacked** (alternate): each prayer is a single row with a Notify toggle and a "customize"
    disclosure; expanding reveals the same override drawer. Summarize the active settings in the row's
    sub-label. Implement only if cheap; Matrix is the spec.
  - Notification-relevant prayers, in order: **Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha** (Ishraq is a
    panel-only window, not a notification).

### Tab 5 — Focus Mode
- **Master** group: "Enable Focus Mode" (Toggle) with sub-label "Covers the entire screen during prayer time."
- **Behaviour** group: "Prayer duration" Stepper (2…45, "N minutes"); "Blur intensity" (pop-up: Low /
  Medium / High / Opaque); "Trigger on" (pop-up: Obligatory prayers / All prayer times / Fajr & Isha only);
  "Emergency exit" (Toggle, sub-label "Allow ⌘⎋ to exit early").
- A full-width "Try it for 10 seconds" button.
- A warning callout: Focus Mode covers the whole screen at each obligatory prayer; it is a discipline aid,
  not a lock — Force Quit always works and it won't engage while a fullscreen app is frontmost.
- **Focus overlay** (when active or previewing): full-screen blurred dark cover (`blur` per the chosen
  intensity; "Opaque" ≈ near-solid dark), centered: small uppercase "Prayer in progress", large prayer
  name (~54pt bold), location + time, and a "Resumes in M:SS" countdown. Esc / click dismisses the preview.

### Menu-bar dropdown panel (NSPopover / MenuBarExtra window)
- Width ~312pt; macOS popover material (translucent, ~13pt corner radius).
- **Header**: location row (pin icon + "Istanbul, Türkiye"), Hijri date (gray), then a "NEXT · <name>"
  label with the next prayer time large on the left and "in H:MM" countdown in accent on the right,
  followed by a thin progress bar showing elapsed fraction between previous and next prayer.
- **List**: every prayer for today (incl. Sunrise, and Ishraq when "Show Ishraq" is on), each row =
  icon + name + time. Past prayers are dimmed (~42% opacity); the **next** prayer row has an
  accent-tinted background and accent-colored name/time. Minor entries (Sunrise/Ishraq) are slightly
  smaller and grayer.
- **Footer**: "Focus now" button (left) and "Settings…" button (right, accent) that opens the
  preferences window.
- **Menu-bar item label** itself reflects the General → "Label style" setting (icon, or icon+countdown,
  or icon+name+countdown like `🕌 Asr 2:34`, or name+time).

---

## Interactions & Behavior
- Tabs switch content instantly; window title updates to the tab name.
- All toggles/steppers/segments mutate persisted settings immediately (no Save button — standard macOS prefs).
- Pop-up buttons in the prototype *cycle* on click only because HTML lacks native menus — implement as
  real `Picker`/pop-up menus.
- "Detect my location" requests Core Location and fills lat/long/elevation.
- "Send a sample notification" posts a `UNUserNotification` styled like a prayer alert (title
  "Prayer Time", body "It's time for <prayer> · <time>", optional sound name).
- Sound preview (▶) plays the selected sound asset.
- Focus "Try it for 10 seconds" shows the overlay with a 10→0 countdown, then auto-dismisses; Esc exits.
- Panel opens on menu-bar item click; the next-prayer countdown and progress bar update live (per second
  is fine).
- Entrance animation for the popover should be **transform-only** (scale/translate), never opacity-based,
  to avoid a blank popover (this was a real bug in the prototype).

## State Management
Persisted settings (UserDefaults / `@AppStorage`), grouped roughly as the tabs:
- General: `launchAtLogin`, `labelStyle`, `countdownShows`, `showIshraq`, `showHijri`, `language`, `autoUpdate`
- Location: `locMode` (auto|manual), `latitude`, `longitude`, `elevation`, `tzMode` (system|explicit), `tz`, `hijriDayAdjustment`
- Calculation: `calcMode` (calculated|manual), `method`, `asrMadhab`, `highLatitudeRule`, `autoDetectMethod`,
  `azanBeforeJamaat` (Int minutes), `manualKeepWaqt` (Bool), `jamaat` (dict prayerKey→"HH:mm" for the 5 obligatory)
- Notifications: `notificationsEnabled`, plus **defaults** (`defaultSound`, `defaultFullAdhan`,
  `defaultEarlyReminder`, `defaultIqamahOffset`) and a per-prayer map keyed by prayer with
  `{ notify, adhan, reminder, sound, fullAdhan, earlyReminder, iqamahOffset }` where sound/reminder/iqamah
  may be a sentinel meaning "inherit default".
- Focus: `focusEnabled`, `focusDurationMinutes`, `focusBlur`, `focusTrigger`, `focusEmergencyExit`
- Derived/live: next prayer + countdown (computed from the active time source), progress fraction.

## Design Tokens
Prefer native macOS equivalents; exact hex values from the prototype for reference:
- **Accent**: system blue `#0A84FF` (use `NSColor.controlAccentColor` / the system accent). Pressed `#0060DF`,
  tint fill `#E9F2FF`. (Prototype also offered green `#1F8A5B` and teal `#0A9BB5` as options — blue is the default.)
- **Text**: primary `#1D1D1F` (`labelColor`), secondary `#6B6B70` (`secondaryLabelColor`), tertiary `#9A9AA0`.
- **Grouped card fill**: `#F4F4F6` (use a grouped/`quaternary` system fill or `.background(.quaternary)`).
- **Window/content background**: white (`windowBackgroundColor` / `textBackgroundColor`).
- **Separators**: `rgba(0,0,0,0.08)` (`separatorColor`).
- **Toggle on**: accent; **off track**: `#E3E3E6`.
- **Corner radius**: window 11, group card 9, small controls 6, popover 13.
- **Row height**: 38 (regular) / 32 (compact).
- **Type**: system font (SF Pro). Section header 13/700, row label 13.5/400, sub-label 11.5 gray,
  panel next-prayer time ~23/700, focus overlay name ~54/700, tab label 11.5/500.
- **Spacing**: content padding 18–22; row padding 7×13; section header margin ~18 top / 8 bottom.
- **Shadows**: window `0 28px 70px rgba(0,0,0,0.42)`; popover `0 12px 40px rgba(0,0,0,0.28)`;
  small controls a 1px hairline + faint drop shadow.

## Assets
- **Icons**: all icons are line-style and map to **SF Symbols** — use SF Symbols natively
  (`gearshape`, `bell`, `moon`, `eye.slash`, `location`, `sunrise`, `sunset`, `sun.max`, `clock`,
  `mappin`, `calendar`, `slider.horizontal.3`, `play.fill`, etc.). The prototype's custom SVGs in
  `components/icons.jsx` are only browser stand-ins.
- **Sounds**: Takbir / Adhan (Makkah) / Adhan (Madinah) / soft chime — supply real audio assets in the app.
- **Sample data** (Istanbul, today): Fajr 03:33, Sunrise 05:27, Ishraq 05:47, Dhuhr 13:14, Asr 17:13,
  Maghrib 20:42, Isha 22:27; Hijri `23 Dhu'l-Hijjah 1447 AH`. These are placeholders for prototype only.

## Files
- `Prayer Time.html` — entry point; mounts the prototype.
- `app.css` — all visual tokens and component styles (the source of truth for spacing/colors/radii).
- `components/app.jsx` — composition: desktop scene, menu bar, panel, settings window, tweaks, focus overlay, toast.
- `components/controls.jsx` — Switch, Popup, Stepper, Segmented, TimeField, Row/Group/Section primitives.
- `components/icons.jsx` — SF-Symbol-style icon set (reference for which SF Symbol to use).
- `components/data.jsx` — sample prayer data + time helpers.
- `components/Panel.jsx` — menu-bar dropdown panel.
- `components/TabBasic.jsx` — General + Location & Time tabs.
- `components/TabCalc.jsx` — Calculation tab incl. Manual/jamaat mode (see `minusMin` for the azan-chip math).
- `components/TabNotif.jsx` — Notifications tab (Matrix + Stacked layouts, override drawer).
- `components/TabFocus.jsx` — Focus Mode tab.
- `tweaks-panel.jsx` — prototype-only control panel for comparing layout/accent/density (not part of the app).

## Implementation order (suggested)
1. Window chrome + tab scaffolding with native toolbar tabs.
2. General + Location & Time (straightforward native controls).
3. **Calculation** incl. the Manual time source + jamaat schedule + azan-offset scheduling.
4. **Notifications** reorg: defaults + per-prayer matrix with override drawer + inheritance.
5. Focus Mode + overlay.
6. Menu-bar `NSStatusItem`/`MenuBarExtra` popover with live countdown.
