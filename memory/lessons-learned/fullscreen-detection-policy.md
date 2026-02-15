# Lesson: Fullscreen Space Detection for Non-Activating Menu Bar Apps

## Date: 2026-02-14

## The Bug

The Dynamic Island floating panel should switch to a compact 4pt handle on fullscreen spaces, but it never did. The panel always remained in full expanded mode regardless of which space the user was on.

## Debugging Journey

### Attempt 1: `NSApplication.shared.currentSystemPresentationOptions.contains(.fullScreen)`

**Hypothesis**: Apple's docs say `currentSystemPresentationOptions` returns "the set of application presentation options that are currently in effect for the system." This should include `.fullScreen` when the active app is fullscreen.

**Result**: Failed. For an LSUIElement (`LSUIElement = YES`) non-activating app, this property always returns `rawValue = 0` (empty). macOS does not propagate the active app's presentation options to background/agent apps. The documentation is misleading — "currently in effect for the system" actually means "what this app's settings are causing the system to display."

### Attempt 2: `NSScreen.visibleFrame` menu bar check

**Hypothesis**: On a fullscreen space the menu bar auto-hides, so `screen.frame.maxY - screen.visibleFrame.maxY` should be ~0 (no menu bar reservation). On a normal desktop it should be ~25-37pt.

**Result**: Failed. `topInset` was always `25.0` regardless of which space the user was on. Because the floating panel has `collectionBehavior = [.canJoinAllSpaces]`, `NSScreen.visibleFrame` returns the same value on every space. The panel's cross-space presence prevents macOS from reporting per-space visible frame changes.

### Attempt 3: `currentSystemPresentationOptions` checking `.autoHideMenuBar`

**Hypothesis**: Even if `.fullScreen` isn't set, `.autoHideMenuBar` should be set on fullscreen spaces because the menu bar auto-hides there.

**Result**: Failed. Same problem as Attempt 1 — `rawValue = 0`, no flags are set at all. The entire `currentSystemPresentationOptions` API is useless for LSUIElement apps.

### Attempt 4 (debug logging): Instrument and observe

Added `os_log` logging to see exact values during space transitions.

**Gotcha**: `Logger` at `.debug` level is NOT persisted by macOS unified logging. Had to change to `.notice` level to see output in `log show`. Use `/usr/bin/log show --process PrayerTime --last 2m --debug --info` to query.

**Key log output on fullscreen space**:
```
signals: raw=0 .fullScreen=false .autoHideMenuBar=false .hideMenuBar=false .autoHideDock=false .hideDock=false
screen topInset=25.000000 menuBarReserved=true desktopAutoHide=false
```

This confirmed: every single public API returns identical values on both normal and fullscreen spaces.

### Attempt 5 (solution): Private CGS API — `CGSCopyManagedDisplaySpaces`

**Approach**: Use private CoreGraphics Server functions to query the window server directly for the current space type.

```swift
private typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ conn: CGSConnectionID) -> CFArray
```

`CGSCopyManagedDisplaySpaces` returns an array of display dictionaries, each containing `"Current Space"` with a `"type"` field. Type `4` = fullscreen space.

**Result**: Works perfectly. Reliably returns the correct space type regardless of app type, sandbox, activation state, or `canJoinAllSpaces`.

## Why Public APIs Fail for This App Type

This app has a unique combination of properties that breaks all standard detection methods:

| Property | Effect on detection |
|---|---|
| `LSUIElement = YES` | App is an agent/background app. `currentSystemPresentationOptions` returns empty. |
| `.nonactivatingPanel` | Panel never activates the app, so the app is never "active" from macOS's perspective. |
| `.canJoinAllSpaces` | Panel appears on all spaces. `NSScreen.visibleFrame` doesn't change per-space. |
| App Sandbox | `CGWindowListCopyWindowInfo` can't see other apps' windows. |

Each property individually might not break detection, but together they eliminate every public API signal.

## The Fix

```swift
private func isCurrentSpaceFullscreen() -> Bool {
    let conn = CGSMainConnectionID()
    guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [[String: Any]] else {
        return false
    }
    for display in displays {
        guard let currentSpace = display["Current Space"] as? [String: Any],
              let spaceType = currentSpace["type"] as? Int else {
            continue
        }
        if spaceType == 4 { return true }  // 4 = fullscreen space
    }
    return false
}
```

Combined with:
- `NSWorkspace.activeSpaceDidChangeNotification` to trigger re-evaluation on space changes
- 300ms settling delay after space change (animation transition time)
- Persisted state that holds until next space change
- 1s positive latch to prevent flicker during rapid transitions

## Rules

1. **Never trust `currentSystemPresentationOptions` in LSUIElement apps** — it always returns empty/default values
2. **Never trust `NSScreen.visibleFrame` for per-space detection in `canJoinAllSpaces` apps** — the value is static across all spaces
3. **`CGWindowListCopyWindowInfo` doesn't work in App Sandbox** — returns only the calling app's own windows
4. **For fullscreen space detection, use `CGSCopyManagedDisplaySpaces`** — it's private API but the only reliable method for this app architecture. Used by Rectangle, Bartender, and many other popular Mac menu bar apps.
5. **`os_log` at `.debug` level is not persisted** — use `.notice` or higher when you need to check logs via `log show` after the fact
6. **Always add instrumented logging before guessing at fixes** — the logs immediately revealed that all signals returned identical values, saving hours of blind iteration

## Debugging Methodology

1. **Read the code** — understand the detection flow end-to-end before changing anything
2. **Hypothesize** — form a theory about why it's broken based on the code and API docs
3. **Instrument** — add logging at the decision point to see actual runtime values
4. **Observe** — reproduce the bug and read the logs to confirm or reject the hypothesis
5. **Iterate** — if the hypothesis was wrong, the logs tell you exactly why, leading to the next hypothesis
6. **Fix** — once the root cause is confirmed by data, implement the minimal fix
7. **Verify** — build, run, test the exact scenario that was broken
