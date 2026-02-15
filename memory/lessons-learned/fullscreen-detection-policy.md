# Lesson: Menu Bar Hidden Is Only a Partial Fullscreen Signal

## Date: 2026-02-14

## What Happened
- Detecting fullscreen from one signal (for example menu bar hidden, or only frontmost window checks) caused wrong Dynamic Island behavior in some states
- macOS can hide menu bar outside fullscreen depending on user settings, and fullscreen menu bar can appear temporarily on hover

## Rule
- Use a concrete multi-signal policy:
  - Strong signal: frontmost app has a near screen-filling visible layer-0 window on current screen
  - Support signal: menu bar hidden + recent active-space transition
- Apply a short positive latch (about 1s) to avoid rapid mode flicker during transitions
- Re-evaluate while panel is visible so fullscreen mode can switch without waiting for a panel recreate
