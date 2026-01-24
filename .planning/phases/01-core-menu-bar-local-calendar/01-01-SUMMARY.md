---
phase: 01-core-menu-bar-local-calendar
plan: 01
subsystem: core-infrastructure
tags: [swift, swiftui, eventkit, menubarextra, xcode]

dependency-graph:
  requires: []
  provides: [xcode-project, menubar-shell, calendar-service, event-model]
  affects: [01-02, 01-03]

tech-stack:
  added: []
  patterns: [singleton-ekstore, menubarextra-window-style]

key-files:
  created:
    - ToEvent/ToEvent.xcodeproj/project.pbxproj
    - ToEvent/ToEvent/ToEventApp.swift
    - ToEvent/ToEvent/Info.plist
    - ToEvent/ToEvent/ToEvent.entitlements
    - ToEvent/ToEvent/Models/Event.swift
    - ToEvent/ToEvent/Models/CalendarInfo.swift
    - ToEvent/ToEvent/Services/CalendarService.swift
  modified: []

decisions:
  - key: menubar-style
    choice: ".menuBarExtraStyle(.window)"
    reason: ".menu style blocks SwiftUI runloop, breaking timers"
  - key: macos-target
    choice: "macOS 13.0 minimum"
    reason: "MenuBarExtra requires macOS 13+, balance reach vs modern APIs"

metrics:
  duration: 4m
  completed: 2026-01-24
---

# Phase 01 Plan 01: Xcode Project Foundation Summary

Xcode project with MenuBarExtra shell and CalendarService singleton wrapping EventKit for calendar data access.

## What Was Built

### Task 1: Xcode Project with MenuBarExtra
- Created `ToEvent.xcodeproj` targeting macOS 13.0+
- MenuBarExtra scene using `.window` style (required for timer compatibility)
- Info.plist with `LSUIElement=YES` (no dock icon)
- Calendar permission strings for macOS 13 and 14+
- Entitlements with calendar sandbox permission
- Asset catalog structure for app icon

### Task 2: CalendarService and Models
- `Event` struct: id, title, startDate, endDate, isAllDay, calendarColor, calendarID
- `CalendarInfo` struct: id, title, color, source
- Both have convenience initializers from EKEvent/EKCalendar
- `CalendarService` singleton with:
  - Private EKEventStore instance
  - Authorization status check
  - Async permission request (macOS 14 API with macOS 13 fallback)
  - `fetchUpcomingEvents(from:lookahead:)` method
  - `getCalendars()` method
  - EKEventStoreChangedNotification subscription via Combine

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| MenuBarExtra style | `.window` | `.menu` style blocks SwiftUI runloop, breaking Timer.publish |
| Deployment target | macOS 13.0 | Earliest version supporting MenuBarExtra; broad user reach |
| Permission API | Dual path | `requestFullAccessToEvents()` on 14+, `requestAccess(to:)` on 13 |
| EKEventStore | Singleton | Apple mandates single instance; CalendarService.shared pattern |

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Hash | Message |
|------|---------|
| 3f9f3f2 | feat(01-01): create Xcode project with MenuBarExtra |
| f20fc6c | feat(01-01): implement CalendarService and Event models |

## Verification Results

- Swift code typechecks without errors
- Project structure matches RESEARCH.md layout
- Info.plist contains both NSCalendarsFullAccessUsageDescription and NSCalendarsUsageDescription
- LSUIElement = YES configured
- CalendarService.shared accessible
- Event and CalendarInfo models defined with Identifiable conformance

## Next Phase Readiness

**Ready for:** Plan 02 (Menu Bar View with Next Event Display)

**Dependencies satisfied:**
- Xcode project builds
- MenuBarExtra scene established
- CalendarService can fetch events
- Event model ready for display formatting

**Known issues:** None

---

*Plan completed: 2026-01-24*
*Duration: 4 minutes*
