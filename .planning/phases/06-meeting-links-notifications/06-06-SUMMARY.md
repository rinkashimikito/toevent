---
phase: 06
plan: 06
subsystem: system-integration
tags: [focus-filter, app-intents, quick-add, calendar-integration]
dependency-graph:
  requires: [06-01]
  provides: [focus-filter-intent, quick-add-event, filtered-events]
  affects: []
tech-stack:
  added: []
  patterns: [SetFocusFilterIntent, UserDefaults-observer, AppleScript-event-creation]
key-files:
  created:
    - ToEvent/ToEvent/Intent/ToEventFocusFilter.swift
    - ToEvent/ToEvent/Views/QuickAddView.swift
  modified:
    - ToEvent/ToEvent/State/AppState.swift
    - ToEvent/ToEvent/Views/MenuBarView.swift
decisions:
  - id: focus-userdefaults
    choice: Store Focus filter state in UserDefaults with notification
    rationale: Simple cross-process communication for Focus intent to AppState
  - id: displayrepresentation
    choice: Dynamic DisplayRepresentation based on filter settings
    rationale: Shows meaningful filter status in Focus UI
  - id: quickadd-applescript
    choice: AppleScript opens Calendar.app with new event
    rationale: Calendar.app provides full event editing UI
metrics:
  duration: 4m
  completed: 2026-01-25
---

# Phase 6 Plan 6: Focus Mode Integration and Quick Add Summary

Focus mode filtering via SetFocusFilterIntent allowing users to show only specific calendars during Focus; quick-add event button in dropdown footer opens Calendar.app with new event.

## What Was Built

### ToEventFocusFilter Intent
- SetFocusFilterIntent implementation for macOS Focus integration
- Parameters for calendar names filter and hide-all option
- Dynamic DisplayRepresentation showing current filter state
- Stores filter to UserDefaults and posts notification

### AppState Focus Filtering
- `filteredEvents` computed property filters by Focus settings
- `allDayEvents` and `timedEvents` now derive from filteredEvents
- Observer for `.focusFilterChanged` notification triggers UI refresh
- Raw `events` property preserved for conflict detection

### QuickAddView
- Simple form with title field and date picker
- Default start time 1 hour from now
- AppleScript creates event in Calendar.app
- Fallback opens Calendar app on script error

### MenuBarView Integration
- Plus button in footer bar (between settings and refresh)
- Shows QuickAddView in popover on tap
- Consistent with existing button styling

## Key Implementation Details

### Focus Filter Storage
```swift
// In ToEventFocusFilter.perform()
UserDefaults.standard.set(calendars, forKey: "focusFilterCalendars")
UserDefaults.standard.set(false, forKey: "focusHideAllEvents")
NotificationCenter.default.post(name: .focusFilterChanged, object: nil)
```

### Filtered Events
```swift
var filteredEvents: [Event] {
    if UserDefaults.standard.bool(forKey: "focusHideAllEvents") {
        return []
    }
    if let focusCalendars = UserDefaults.standard.stringArray(forKey: "focusFilterCalendars"),
       !focusCalendars.isEmpty {
        return events.filter { focusCalendars.contains($0.calendarTitle) }
    }
    return events
}
```

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Focus state storage | UserDefaults with notification | Cross-process communication between Intent and main app |
| DisplayRepresentation | Dynamic based on current filter | Meaningful status in Focus settings UI |
| Quick add approach | AppleScript to Calendar.app | Delegates full event editing to Calendar app |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added displayRepresentation to ToEventFocusFilter**
- **Found during:** Task 1
- **Issue:** SetFocusFilterIntent requires displayRepresentation property for protocol conformance
- **Fix:** Added computed property returning descriptive text based on filter state
- **Commit:** 6b9d330

## Files Changed

| File | Change |
|------|--------|
| ToEvent/ToEvent/Intent/ToEventFocusFilter.swift | Created - Focus filter intent |
| ToEvent/ToEvent/Views/QuickAddView.swift | Created - Quick add event view |
| ToEvent/ToEvent/State/AppState.swift | Added filteredEvents, focus observer |
| ToEvent/ToEvent/Views/MenuBarView.swift | Added quick-add button |
| ToEvent/ToEvent.xcodeproj/project.pbxproj | Added new files to project |

## Commits

| Hash | Message |
|------|---------|
| 6b9d330 | feat(06-06): add ToEventFocusFilter intent for Focus mode integration |
| dd2e717 | feat(06-06): add Focus mode filter support to AppState |
| b55c3c9 | feat(06-06): add QuickAddView and integrate with dropdown footer |

## Next Phase Readiness

Phase 6 complete. Ready for Phase 7 (Polish and Testing).

### Remaining Work
None - all Phase 6 plans completed.
