# Feature: Floating Notification Panel

## Status: Not Started

## Requirements
- Dynamic Island-like capsule at top center of screen
- Appears X minutes before prayer (configurable, 0-60 min, 5-min increments)
- Shows: prayer SF Symbol icon + prayer name + live countdown
- Uses AppKit NSPanel (not SwiftUI window) for:
  - Non-activating (.nonactivatingPanel) — never steals focus
  - Always on top (.floating level)
  - Visible across all Spaces (.canJoinAllSpaces + .stationary)
  - canBecomeKey/canBecomeMain = false
  - hidesOnDeactivate = false
- Capsule shape, ~300x56pt
- Auto-dismisses when prayer time arrives
- Click to dismiss
- SwiftUI content via NSHostingView

## Visual Style
- **Dark opaque background** — NOT Liquid Glass. Matches macOS Dynamic Island aesthetic (see reference image)
- Dark fill (e.g., `Color.black.opacity(0.85)`) with large `cornerRadius` for capsule shape
- Light/white text and icons on dark background
- Positioned at top center of screen, just below menu bar / notch area
- This is intentionally different from the main app popover which uses Liquid Glass
- The NSPanel is a separate window so there is zero style conflict with the main app

## Implementation Notes
_To be filled during development_

## Open Issues
_None yet_
