# Lesson: `.fullScreenAuxiliary` Alone Is Not a UX Fix

## Date: 2026-02-14

## What Happened
- Adding `.fullScreenAuxiliary` to the floating panel improved space eligibility but did not reliably solve the fullscreen UX issue by itself
- In practice, users still felt the island behavior was awkward in fullscreen apps

## Rule
- Keep `.fullScreenAuxiliary` for compatibility, but use explicit fullscreen-mode behavior for UX
- In fullscreen mode, render a compact top handle (4pt) and expand on hover
- Collapse back on hover exit with a short delay so accidental pointer movement does not cause jitter
- Drive fullscreen mode from multi-signal detection instead of a single heuristic
