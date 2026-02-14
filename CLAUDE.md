# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PrayerTime is a macOS menu bar app for Islamic prayer times. Built with SwiftUI + AppKit interop, targeting macOS 15.0+ with Liquid Glass on macOS 26. Uses the Adhan Swift library for offline prayer time calculation. No Dock icon — runs exclusively in the menu bar.

Full requirements: `docs/PRD.md`
Implementation plan: `docs/PLAN.md`

## Architecture

**Pattern**: MVVM
- **Models** (`PrayerTime/Models/`): Data structs, enums, UserDefaults keys
- **ViewModels** (`PrayerTime/ViewModels/`): `PrayerViewModel` (central hub with 1s timer), `SettingsViewModel`, `LocationViewModel`
- **Views** (`PrayerTime/Views/`): SwiftUI views, `Components/` subfolder for reusable pieces
- **Services** (`PrayerTime/Services/`): `PrayerCalculationService` (wraps Adhan), `LocationService` (CoreLocation), `NotificationService` (UNUserNotificationCenter)
- **Utilities** (`PrayerTime/Utilities/`): `FloatingPanel` (NSPanel subclass), `FloatingPanelManager`, `ViewExtensions`

**Key architectural decisions**:
- `MenuBarExtra(.window)` is the app entry point — not a standard window-based app
- Floating notification panel uses AppKit `NSPanel` with `NSHostingView` for SwiftUI content — this is intentional to get non-activating, always-on-top, cross-Space behavior that pure SwiftUI cannot provide
- `adaptiveGlass()` view modifier conditionally applies Liquid Glass (macOS 26) or `.ultraThinMaterial` (macOS 15+) — all glass effects go through this single modifier
- Prayer times recalculate on: midnight, wake-from-sleep (`NSWorkspace.didWakeNotification`), and settings changes

## Build Commands

```bash
# Build from command line
xcodebuild -scheme PrayerTime -configuration Debug build

# Build for release
xcodebuild -scheme PrayerTime -configuration Release build

# Open in Xcode
open PrayerTime.xcodeproj
```

## Dependencies

- **Adhan Swift** (`https://github.com/batoulapps/adhan-swift`): Prayer time calculation via SPM
- No other external dependencies

## Entitlements & Info.plist

- `LSUIElement = YES` — hides from Dock
- App Sandbox: Outgoing Connections (for geocoding), Location
- `NSLocationWhenInUseUsageDescription` — required for CoreLocation

## SF Symbols Used

| Prayer   | Symbol                  |
|----------|------------------------|
| Fajr     | `sunrise.fill`         |
| Sunrise  | `sun.horizon.fill`     |
| Dhuhr    | `sun.max.fill`         |
| Asr      | `sun.and.horizon.fill` |
| Maghrib  | `sunset.fill`          |
| Isha     | `moon.stars.fill`      |

## Edge Cases to Always Consider

- **After Isha**: Next prayer is tomorrow's Fajr — must calculate tomorrow's times
- **High latitude**: Adhan handles via `HighLatitudeRule`; display "N/A" if calculation impossible
- **No location set**: Show location setup prompt, disable notifications
- **Location permission denied**: Hide auto-detect button, show manual search only

## Memory System

This project uses a `memory/` folder to persist knowledge across sessions:

- **`memory/progress.md`** — Current project state, what phase we're in, what's done/remaining
- **`memory/lessons-learned/`** — Individual markdown files for mistakes, gotchas, and insights discovered during development. Create a new file per topic (e.g., `floating-panel-focus.md`, `adhan-api-quirks.md`)
- **`memory/features/`** — One markdown file per feature tracking its status, implementation notes, and any open issues (e.g., `menu-bar.md`, `floating-panel.md`, `sun-arc.md`)

**Rules**:
1. After completing any feature or significant task, update `memory/progress.md` with current state
2. When encountering a non-obvious bug, workaround, or API behavior, create/update a file in `memory/lessons-learned/`
3. When starting or finishing a feature, update its file in `memory/features/`
4. Read `memory/progress.md` at the start of each session to understand current state
