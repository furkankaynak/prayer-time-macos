# Feature: Floating Notification Panel

## Status: Complete (styling refinement in progress)

## Requirements
- Dynamic Island-like capsule at top center of screen
- Appears X minutes before prayer (configurable, 0-60 min, 5-min increments)
- Shows: prayer SF Symbol icon + prayer name + live countdown
- Uses AppKit NSPanel (not SwiftUI window) for:
  - Non-activating (.nonactivatingPanel) — never steals focus
  - Always on top (.statusBar level) — above menu bar
  - Visible across all Spaces (.canJoinAllSpaces + .stationary)
  - canBecomeKey/canBecomeMain = false
  - hidesOnDeactivate = false
- Capsule shape, 320x52pt
- Auto-dismisses when prayer time arrives
- Click to dismiss
- SwiftUI content via NSHostingView
- Settings: "Show floating panel" toggle + "Always show Dynamic Island" toggle

## Visual Style — Design Tokens
- **Surface**: `#070707` (rgb 7,7,7) — very deep neutral black, NOT pure #000
- **Shape**: Capsule (superellipse pill, `border-radius: 9999px` equivalent)
- **Border**: none (no physical border)
- **Rim light**: `rgba(255,255,255, 0.03–0.05)` — barely perceptible, uniform 0.5pt stroke
- **Shadow**: soft diffused black `rgba(0,0,0, 0.35–0.45)` — single soft layer
- **Surface feel**: matte + soft glass, low glare
- Light/white text and icons on dark background
- Positioned at very top of screen, above menu bar (uses `screen.frame` not `visibleFrame`)

## Critical Implementation Details
- **Window level MUST be `.statusBar`** — `.floating` puts it below menu bar, `.statusBar` puts it above
- **Positioning MUST use `screen.frame`** — `visibleFrame` excludes menu bar area, `screen.frame` includes full screen
- NSPanel `hasShadow = true` — AppKit-level shadow for the window itself
- SwiftUI shadow is additional visual layer on the capsule content

## Implementation Notes
- Phase 6: initial implementation with basic styling (Color.black, RoundedRectangle, single shadow)
- Phase 7: accessibility labels, hint, button trait added
- Post-phase: `level` changed from `.floating` to `.statusBar`, positioning from `visibleFrame` to `screen.frame`
- Styling refinement branch: `feature/dynamic-island-styling` — updates to match design reference

## Open Issues
- Styling refinement needs to be merged (capsule shape, #070707 surface, rim light, soft shadow)
