---
phase: 01-core-menu-bar-local-calendar
plan: 02
subsystem: ui-core
tags: [swift, swiftui, menubarextra, timelineview, eventkit]

dependency-graph:
  requires: [01-01]
  provides: [menu-bar-display, intro-flow, app-state]
  affects: [01-03]

tech-stack:
  added: []
  patterns: [observableobject-state, timelineview-periodic, environment-injection]

key-files:
  created:
    - ToEvent/ToEvent/State/AppState.swift
    - ToEvent/ToEvent/Utilities/DateFormatters.swift
    - ToEvent/ToEvent/Views/MenuBarView.swift
    - ToEvent/ToEvent/Views/IntroView.swift
  modified:
    - ToEvent/ToEvent/ToEventApp.swift
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - key: observable-pattern
    choice: "ObservableObject over @Observable"
    reason: "macOS 13.0 compatibility; @Observable requires macOS 14+"
  - key: intro-in-menubar
    choice: "IntroView inside MenuBarExtra window"
    reason: "Simpler than separate Window scene; same dropdown pattern"

metrics:
  duration: 5m
  completed: 2026-01-24
---

# Phase 01 Plan 02: Menu Bar View and Intro Flow Summary

Menu bar displays next event with colored dot, title, and relative time. Intro flow requests calendar permission on first launch.

## What Was Built

### Task 1: AppState and DateFormatters
- `AppState` as ObservableObject with @Published properties
- Persisted preferences: hasCompletedIntro, enabledCalendarIDs, lookahead
- Auto-refresh on EKEventStoreChangedNotification via Combine
- `DateFormatters.formatRelativeTime` returning "in Xm" or "in Xh" format
- Edge cases: "now" for past events, "in 1m" for <60 seconds

### Task 2: MenuBarView with TimelineView
- TimelineView with .periodic(from: .now, by: 60) for minute updates
- HStack layout: colored Circle (8x8), truncated title, relative time
- All-day events show "Today" instead of countdown
- "All clear" displayed when no upcoming events
- Title truncation at 22 characters with ellipsis

### Task 3: IntroView with Permission Flow
- Displayed inside MenuBarExtra window on first launch
- Calendar icon + headline explaining value proposition
- "Get Started" button triggers async permission request
- Permission denied state shows "Open System Settings" button
- Deep-links to Privacy & Security > Calendar settings
- Dismisses after permission granted, refreshes events

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Observable pattern | ObservableObject | @Observable requires macOS 14+; project targets macOS 13.0 |
| Intro location | Inside MenuBarExtra | Avoids complexity of Window scene + openWindow |
| Time format | "in Xm" | Matches plan spec; clear relative timing |
| Truncation limit | 22 characters | Plan specified ~20-25; 22 provides balance |

## Deviations from Plan

None - plan executed exactly as written. The plan anticipated ObservableObject fallback for macOS 13 compatibility.

## Commits

| Hash | Message |
|------|---------|
| 93de7bb | feat(01-02): add AppState and DateFormatters |
| 49dc722 | feat(01-02): implement MenuBarView with TimelineView |
| 9914c4b | feat(01-02): implement IntroView with permission flow |

## Verification Results

- Swift code typechecks without errors
- TimelineView present in MenuBarView.swift
- requestAccess called from IntroView
- DateComponentsFormatter used in DateFormatters
- EnvironmentObject injection pattern verified
- appState.nextEvent accessed in MenuBarView

## Next Phase Readiness

**Ready for:** Plan 03 (Calendar Selection Settings)

**Dependencies satisfied:**
- AppState.enabledCalendarIDs ready for settings UI
- CalendarService.getCalendars() available
- hasCompletedIntro gate operational

**Known issues:** None

---

*Plan completed: 2026-01-24*
*Duration: 5 minutes*
