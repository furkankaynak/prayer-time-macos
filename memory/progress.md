# Project Progress

## Current Phase: Phase 2 — Services (Next)

## Completed
- [x] PRD written (`docs/PRD.md`)
- [x] Implementation plan written (`docs/PLAN.md`)
- [x] CLAUDE.md created
- [x] Memory system set up
- [x] Phase 0: Project Setup
  - Xcode project created (`PrayerTime.xcodeproj`)
  - macOS 15.0 deployment target, Swift 5
  - `LSUIElement = YES` in Info.plist (no Dock icon)
  - App Sandbox: outgoing connections + location
  - `NSLocationWhenInUseUsageDescription` in Info.plist
  - Adhan Swift 1.4.0 via SPM (resolved and compiles)
  - Shared xcscheme created
  - Entitlements configured
  - Minimal `MenuBarExtra` entry point (`PrayerTimeApp.swift`)
  - Folder groups: App, Models, ViewModels, Views/Components, Services, Utilities
  - Build verified: **BUILD SUCCEEDED**
- [x] Phase 1: Models
  - `AppSettings.swift` — `AppSettingsKeys`, `CalculationMethodOption` (12 methods), `MadhabOption`, `AppDefaults`
  - `PrayerTimeModel.swift` — `Prayer` extension (`@retroactive Identifiable`, `displayName`, `sfSymbol`), `PrayerTimeEntry`, `DailyPrayerTimes`
  - `LocationModel.swift` — `SavedLocation` (Codable, Equatable), `LocationSearchResult` (with CLPlacemark factory init)
  - All 3 files registered in pbxproj under Models group
  - Build verified: **BUILD SUCCEEDED**

## In Progress
_None_

## Remaining Phases
- [ ] Phase 2: Services (PrayerCalculation, Location, Notification)
- [ ] Phase 3: ViewModels (Prayer, Settings, Location)
- [ ] Phase 4: Main UI Views (App entry, MainView, SunPositionView, PrayerListView)
- [ ] Phase 5: Settings View
- [ ] Phase 6: Floating Panel (NSPanel, FloatingPanelView, Manager)
- [ ] Phase 7: Polish (Liquid Glass, animations, accessibility)

## Last Updated
2026-02-13 — Phase 1 complete, build verified
