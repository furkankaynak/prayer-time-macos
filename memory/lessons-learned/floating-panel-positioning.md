# Lesson: FloatingPanel Positioning — Don't Use ContainerView

## Date: 2026-02-14

## What Happened
- Tried wrapping NSHostingView in an intermediary NSView (containerView) to fix background transparency
- This broke the panel's top-edge positioning — panel no longer sat flush at the screen top
- The extra view layer interfered with NSPanel's frame/contentView relationship

## Rule
- **ALWAYS set hostingView directly as panel's contentView** — `floatingPanel.contentView = hostingView`
- Do NOT insert intermediary NSView containers between the panel and the hosting view
- The original pattern (hostingView → contentView, 320x52 frame) is the working baseline
- `hasShadow = true` must stay on — it's part of the working configuration
