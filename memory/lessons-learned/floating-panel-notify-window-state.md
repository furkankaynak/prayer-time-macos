# Lesson: Notify Window Requires Persistent Visibility State

## Date: 2026-02-14

## What Happened
- Floating panel visibility during notify window was gated by a one-time marker (`floatingPanelShownForPrayer`)
- Panel showed once, then next timer tick set `shouldShowFloatingPanel = false` even though notify window was still active
- Result: with "Always show Dynamic Island" disabled, panel disappeared during the active pre-prayer window

## Rule
- For notify-window mode, panel visibility must remain true for the full trigger window (`triggerTime ... prayerTime`) unless user explicitly dismisses
- Track dismissal by `nextPrayerTime` (Date), not only prayer enum, to avoid collisions across days
- Clear stale dismissal state when the tracked `nextPrayerTime` changes or after the prayer time passes
