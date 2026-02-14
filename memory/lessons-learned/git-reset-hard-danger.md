# Lesson: git reset --hard Destroys Uncommitted Work

## Date: 2026-02-13

## What Happened
- `git status` at session start showed `M PrayerTime/Utilities/FloatingPanel.swift` (uncommitted changes)
- These changes were important: `level = .statusBar` (panel above menu bar) and `screen.frame` positioning (full screen coordinates instead of `visibleFrame`)
- During a revert of a bad feature branch, `git reset --hard 07c5a12` was used, which wiped out all uncommitted changes
- The panel stopped appearing at the top of screen because it reverted to `level = .floating` and `visibleFrame` positioning

## Root Cause
- Did not stash or commit the user's uncommitted work before doing destructive git operations
- `git reset --hard` discards both staged and unstaged changes with no recovery

## Rule
- **ALWAYS** check `git status` and `git stash` uncommitted changes before any `git reset --hard` or branch switching that could lose work
- If there are uncommitted modifications, stash them first: `git stash push -m "WIP before reset"`
- After the operation, restore with `git stash pop`

## Fix Applied
- Manually restored the two changes:
  - `level = .floating` -> `level = .statusBar`
  - `visibleFrame` -> `screen.frame`
- Committed to main so they won't be lost again
