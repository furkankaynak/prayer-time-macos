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

## Git Workflow

Each phase or feature is implemented on its own branch:

1. `git checkout main && git pull origin main` — start from latest main
2. `git checkout -b feature/<phase-or-feature-name>` — create feature branch
3. Implement, build, verify
4. `git add <files> && git commit` — commit changes
5. `git push -u origin feature/<phase-or-feature-name>` — push branch
6. `git checkout main` — return to main when done

Branch naming: `feature/phase-5-settings-view`, `feature/phase-6-floating-panel`, etc.

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

## macOS API Constraints for This App

This app has a unique combination of properties (`LSUIElement`, `.nonactivatingPanel`, `.canJoinAllSpaces`, App Sandbox) that breaks most standard macOS APIs. Before using any system API, check against these known dead ends:

| API | Status | Why it fails |
|---|---|---|
| `NSApplication.shared.currentSystemPresentationOptions` | **Dead** | Always returns `rawValue = 0` for LSUIElement apps. Does not reflect the active app's state. |
| `NSScreen.visibleFrame` (per-space) | **Dead** | Returns the same values on every space when the app uses `.canJoinAllSpaces`. |
| `CGWindowListCopyWindowInfo` | **Dead** | App Sandbox blocks enumeration of other apps' windows. Only returns own windows. |
| `CGSCopyManagedDisplaySpaces` (private) | **Works** | Queries the window server directly. Returns current space type (4 = fullscreen). The only reliable fullscreen detection for this app type. |

**Rule**: When a public API seems like the right answer based on Apple's docs, verify it with debug logging before building a feature on it. Apple's documentation often describes behavior for standard activating apps, not LSUIElement/agent apps.

## Debugging Methodology

When fixing bugs in this codebase, follow this methodology — especially for macOS system integration issues where API behavior may differ from documentation:

1. **Read the code** — understand the full detection/logic flow end-to-end before changing anything. Trace from the trigger (e.g., space change notification) through to the UI effect.
2. **Hypothesize** — form a specific, testable theory about the root cause based on code reading and API docs.
3. **Instrument** — add `os_log` logging (at `.notice` level or higher — `.debug` is NOT persisted by macOS unified logging) at the decision points to capture actual runtime values.
4. **Observe** — build, run, reproduce the bug, then query logs: `/usr/bin/log show --process PrayerTime --last 2m --debug --info 2>&1 | grep <keyword>`
5. **Analyze** — compare expected vs actual values in the logs. The data tells you which signal is broken.
6. **Fix** — implement the minimal change that addresses the confirmed root cause. Don't guess.
7. **Verify** — build, run, test the exact scenario that was broken.

**Key principle**: Never iterate blindly. One round of instrumented logging reveals more than five rounds of "try this API instead." Logs turn a mystery into a data problem.

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
