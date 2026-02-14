# PrayerTime for macOS — Implementation Plan

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **UI**: SwiftUI with AppKit interop (NSPanel for floating window)
- **Target**: macOS 15.0+ with Liquid Glass conditional on macOS 26
- **Dependency**: Adhan Swift via Swift Package Manager

## File Structure

PrayerTime/
├── App/
│   └── PrayerTimeApp.swift
├── Models/
│   ├── PrayerTimeModel.swift
│   ├── LocationModel.swift
│   └── AppSettings.swift
├── ViewModels/
│   ├── PrayerViewModel.swift
│   ├── SettingsViewModel.swift
│   └── LocationViewModel.swift
├── Views/
│   ├── MainView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── SunPositionView.swift
│       ├── PrayerListView.swift
│       └── FloatingPanelView.swift
├── Services/
│   ├── PrayerCalculationService.swift
│   ├── LocationService.swift
│   └── NotificationService.swift
├── Utilities/
│   ├── FloatingPanel.swift
│   ├── FloatingPanelManager.swift
│   └── ViewExtensions.swift
└── Assets.xcassets/

## Build Order

### Phase 0: Project Setup
1. Create Xcode macOS App project (SwiftUI, Swift, macOS 15.0)
2. Set `LSUIElement = YES` in Info.plist (no Dock icon)
3. Add Adhan Swift via SPM: `https://github.com/batoulapps/adhan-swift`
4. Enable App Sandbox: Outgoing Connections, Location
5. Add `NSLocationWhenInUseUsageDescription` to Info.plist
6. Create folder groups matching the file structure above

### Phase 1: Models
- **PrayerTimeModel.swift**: `PrayerTimeEntry` struct (prayer enum, name, time, SF Symbol icon, formatted time). `DailyPrayerTimes` struct (date, entries array, sunrise, sunset, Adhan PrayerTimes reference for currentPrayer/nextPrayer lookups).
- **LocationModel.swift**: `SavedLocation` struct (lat, lon, city, country, timeZone — Codable for UserDefaults). `LocationSearchResult` (wraps CLPlacemark).
- **AppSettings.swift**: UserDefaults key constants. `CalculationMethodOption` enum (all 12 methods) with `rawValue` display names and computed `adhanMethod` property mapping to Adhan's `CalculationMethod`.

### Phase 2: Services
- **PrayerCalculationService.swift**: Pure computation service. `calculatePrayerTimes(lat:lon:date:method:madhab:)` → `DailyPrayerTimes?`. `recommendedMethod(for timeZone:)` maps timezone identifiers to methods (Americas→ISNA, Europe/Istanbul→Turkey, Europe→MWL, Asia/Riyadh→UmmAlQura, etc.). Uses `HighLatitudeRule.recommended(for:)` for high latitudes.
- **LocationService.swift**: `CLLocationManagerDelegate`. `requestLocation()` for auto-detect. `searchLocations(query:)` async using `CLGeocoder.geocodeAddressString()`. Reverse geocodes to get city/country/timezone.
- **NotificationService.swift**: `requestAuthorization()`. `scheduleNotifications(for:minutesBefore:)` creates `UNCalendarNotificationTrigger` for each prayer (except Sunrise). Clears and re-schedules daily.

### Phase 3: ViewModels
- **SettingsViewModel.swift**: `@Published` properties persisted via UserDefaults didSet: savedLocation, selectedMethod, selectedMadhab, notificationMinutes, showFloatingPanel. `autoDetectMethod()` calls PrayerCalculationService.recommendedMethod.
- **PrayerViewModel.swift**: Central hub. 1-second Timer.publish drives: currentPrayer/nextPrayer (from Adhan), countdownText, menuBarText (next prayer name + time), sunProgress (0.0→1.0 for arc). Observes SettingsViewModel changes to recalculate. Handles after-Isha (calculate tomorrow's Fajr). Midnight recalculation. Wake-from-sleep recalculation via NSWorkspace.didWakeNotification. Floating panel trigger checking.
- **LocationViewModel.swift**: Search text with 300ms debounce. searchResults array. detectLocation() flow. selectResult() converts CLPlacemark to SavedLocation.

### Phase 4: Main UI Views
- **PrayerTimeApp.swift**: `@main` with `MenuBarExtra(.window)`. Label: SF Symbol (changes per prayer) + menuBarText. Creates and injects all ViewModels/services via .environmentObject().
- **MainView.swift**: 320×420pt. Header (city name + date + gear button). SunPositionView. Divider. PrayerListView. @State showSettings toggles to SettingsView.
- **SunPositionView.swift**: Semicircle arc drawn with SwiftUI Path. Dashed horizon line. Gradient stroke. Sun icon positioned via trig: angle = 180° - (progress × 180°), x = center + radius×cos(angle), y = center - radius×sin(angle). Traversed arc highlighted. Sunrise/sunset time labels at endpoints.
- **PrayerListView.swift**: ForEach over entries. PrayerRow: icon + name + countdown (next only, orange) + formatted time. Next prayer: orange bg, semibold. Current: blue tint. Past: dimmed.

### Phase 5: Settings View
- **SettingsView.swift**: Sections — Location (current display + search field + results + "Use My Location" button), Calculation Method (Picker + Madhab segmented), Notifications (Stepper for minutes + floating panel Toggle), About.

### Phase 6: Floating Panel
- **FloatingPanel.swift**: NSPanel subclass. Styles: .nonactivatingPanel, .borderless, .fullSizeContentView. Level: .floating. canBecomeKey/canBecomeMain → false. hidesOnDeactivate = false. .canJoinAllSpaces + .stationary. positionAtTopCenter() method.
- **FloatingPanelView.swift**: Capsule HStack (300×56pt): prayer icon + name + countdown (TimelineView for live updates). .adaptiveGlass(). Tap to dismiss.
- **FloatingPanelManager.swift**: show() creates panel with NSHostingView, positions, shows. Auto-dismiss timer at prayer time. dismiss() closes panel.

### Phase 7: Polish
- **ViewExtensions.swift**: `adaptiveGlass()` — glassEffect on macOS 26+, ultraThinMaterial on 15+. `adaptiveBackground()` for main view.
- Wire floating panel trigger into PrayerViewModel.updateCurrentState()
- Animations on prayer transitions, sun movement
- VoiceOver labels on all interactive elements
- Test with Reduced Motion, Reduced Transparency, Increased Contrast

## SF Symbols Mapping

| Prayer   | Symbol                  |
|----------|------------------------|
| Fajr     | `sunrise.fill`         |
| Sunrise  | `sun.horizon.fill`     |
| Dhuhr    | `sun.max.fill`         |
| Asr      | `sun.and.horizon.fill` |
| Maghrib  | `sunset.fill`          |
| Isha     | `moon.stars.fill`      |

## Edge Cases

1. **After Isha**: Calculate tomorrow's times, show Fajr as next
2. **High latitude**: Adhan handles via HighLatitudeRule; show "N/A" if impossible
3. **No location set**: Prompt user to set location, disable notifications
4. **Location denied**: Hide auto-detect, show manual search only
5. **Wake from sleep**: Recalculate on NSWorkspace.didWakeNotification
6. **Day change**: Recalculate at midnight

## Verification Checklist

- [ ] App appears in menu bar with correct icon and prayer text
- [ ] Searching "Istanbul" shows Istanbul prayer times
- [ ] Searching "Vancouver" shows different prayer times
- [ ] "Use My Location" detects correct city and auto-selects method
- [ ] Sun icon moves along arc matching real time
- [ ] Next prayer highlighted with orange countdown
- [ ] Menu bar text updates as prayers pass
- [ ] Floating panel appears X minutes before prayer with countdown
- [ ] Floating panel auto-dismisses at prayer time
- [ ] Floating panel does not steal focus
- [ ] Settings persist across app restarts
- [ ] System notification appears in Notification Center
- [ ] macOS 26: Liquid Glass effects visible
- [ ] macOS 15: Clean material fallback
