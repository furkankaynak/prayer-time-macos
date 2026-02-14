# PrayerTime for macOS — Product Requirements Document

## Overview

PrayerTime is a lightweight, minimalist macOS menu bar application for Muslims to track the five daily Islamic prayer times (Salah). The app lives in the macOS status bar, providing at-a-glance access to prayer schedules with a beautiful sun position visualization and timely notifications before each prayer.

## Problem Statement

Muslims need to track five daily prayer times that change every day based on astronomical calculations and geographic location. Existing solutions are either web-based, mobile-only, or heavy desktop apps. There is no lightweight, native macOS menu bar app that provides prayer times with a modern, elegant interface.

## Target User

Muslims who use macOS as their primary computer and want a convenient, always-visible reminder of prayer times without switching to a phone or browser.

## Core Features

### 1. Menu Bar Presence
- The app runs exclusively in the macOS menu bar (no Dock icon)
- Displays the next upcoming prayer name and time directly in the status bar (e.g., "☀️ Dhuhr 12:30")
- The icon changes dynamically based on the current prayer period (sunrise, sun, sunset, moon icons)
- Clicking the menu bar item opens a popover window with the full interface

### 2. Main View — Prayer Times Dashboard
- **Sun Position Arc**: A semicircular arc visualization showing the sun's current position between sunrise and sunset. The sun icon animates along the arc in real-time, giving users an intuitive sense of where they are in the day.
- **Prayer Times List**: All five daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) plus Sunrise are listed with their calculated times
  - The current prayer period is subtly highlighted
  - The next upcoming prayer is prominently highlighted with a live countdown timer
  - Past prayers are dimmed
- **Header**: Shows the selected city name, current date, and a gear icon to access settings

### 3. Location Selection
- **Auto-Detect**: "Use My Location" button that uses macOS CoreLocation to detect the user's current position and reverse-geocode it to a city name
- **Manual Search**: A text search field where users can type any city name worldwide (e.g., "Istanbul", "Vancouver", "Cairo"). Results are geocoded using Apple's CLGeocoder
- The app can calculate prayer times for ANY location on Earth — a user in Vancouver can view Istanbul's prayer times by simply searching for Istanbul

### 4. Settings
- **Location**: Change or update the selected location
- **Calculation Method**: Auto-detected based on the location's timezone region, but user-selectable. Supported methods:
  - ISNA (Islamic Society of North America) — default for Americas
  - MWL (Muslim World League) — default for Europe
  - Diyanet (Turkey) — default for Turkey
  - Egyptian General Authority — default for North Africa
  - Umm Al-Qura — default for Saudi Arabia/Middle East
  - University of Karachi — default for South Asia
  - And more (Dubai, Kuwait, Qatar, Singapore, Tehran, Moonsighting Committee)
- **Madhab**: Shafi (default) or Hanafi — affects Asr prayer time calculation
- **Notification Timing**: Configure how many minutes before each prayer the app should notify (0–60 minutes, in 5-minute increments)
- **Floating Panel Toggle**: Enable/disable the floating notification panel

### 5. Floating Notification Panel (Dynamic Island-like)
- When the configured notification period begins (e.g., 15 minutes before Dhuhr), a small floating capsule-shaped panel appears at the top center of the screen
- The panel displays:
  - The prayer's SF Symbol icon (e.g., sun icon for Dhuhr)
  - The prayer name
  - A live countdown timer showing remaining time until prayer
- The panel:
  - Floats above all other windows (always on top)
  - Does NOT steal keyboard focus or interrupt the user's workflow
  - Is visible across all Spaces/desktops
  - Auto-dismisses when the prayer time arrives
  - Can be dismissed by clicking on it
- Additionally, a standard macOS system notification is sent via Notification Center

### 6. Prayer Time Calculation
- All prayer times are calculated locally/offline using the Adhan Swift library — no internet connection required after initial location setup
- Calculations use high-precision astronomical algorithms from "Astronomical Algorithms" by Jean Meeus
- Supports high-latitude adjustments for locations where Fajr/Isha may not occur normally (e.g., Scandinavia in summer)
- Prayer times automatically recalculate at midnight and after the Mac wakes from sleep

## Design Language

- **macOS 26+ (Tahoe)**: Liquid Glass design — translucent glass effects on navigation/control elements (floating panel, backgrounds), creating a modern, elegant appearance
- **macOS 15–25**: Clean fallback using `.ultraThinMaterial` for a frosted glass look
- **Minimalist**: No unnecessary chrome, focused on content
- **Fancy**: Smooth animations, gradient sun arc, dynamic SF Symbol icons
- **Native**: Follows macOS conventions — standard keyboard shortcuts, VoiceOver accessible, respects system appearance (light/dark mode)

## Technical Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift |
| UI Framework | SwiftUI |
| Prayer Calculation | [Adhan Swift](https://github.com/batoulapps/adhan-swift) (SPM) |
| Location | CoreLocation + CLGeocoder |
| Notifications | UserNotifications (UNUserNotificationCenter) |
| Floating Panel | AppKit NSPanel (interop) |
| Persistence | UserDefaults / @AppStorage |
| Min. Deployment | macOS 15.0 |

## Non-Functional Requirements

- **Lightweight**: Minimal memory footprint, no background network requests
- **Battery-efficient**: 1-second timer only for countdown updates; consider throttling when popover is closed
- **Offline-first**: Prayer calculation works without internet
- **Accessible**: VoiceOver labels, keyboard navigation, respects Reduced Motion/Transparency settings
- **Persistent**: Settings survive app restarts

## Out of Scope (v1.0)

- Qibla direction compass
- Hijri calendar display
- Adhan (call to prayer) audio playback
- Multiple saved locations / favorites
- Widget for macOS Notification Center
- iOS/watchOS companion apps
- Localization (English only for v1.0)

## Success Metrics

- App launches in < 1 second
- Prayer times match reference sources (e.g., aladhan.com) within ±1 minute
- Floating panel appears reliably and never steals focus
- App uses < 50MB RAM during normal operation
