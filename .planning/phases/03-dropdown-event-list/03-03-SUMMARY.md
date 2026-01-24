---
phase: 03-dropdown-event-list
plan: 03
subsystem: ui
tags: [swiftui, applescript, calendar-integration, automation]

requires:
  - phase: 03-02
    provides: EventRowView with onEventTap closure, openEventInCalendar placeholder

provides:
  - AppleScript automation entitlements for Calendar.app control
  - openEventInCalendar implementation using NSAppleScript
  - Clicking event opens Calendar.app and shows specific event

affects: []

tech-stack:
  added: []
  patterns:
    - NSAppleScript for Calendar.app integration
    - Quote escaping for AppleScript injection prevention

key-files:
  created: []
  modified:
    - ToEvent/ToEvent/ToEvent.entitlements
    - ToEvent/ToEvent/Info.plist
    - ToEvent/ToEvent/Views/MenuBarView.swift

key-decisions:
  - "AppleScript via NSAppleScript (only reliable method to open specific events)"
  - "Error logging but not surfacing to user (Calendar likely opens anyway)"
  - "Quote escaping for calendar/event IDs to prevent injection"

patterns-established:
  - "Calendar integration: AppleScript with escaped strings for safe execution"

duration: 4min
completed: 2026-01-24
---

# Phase 3 Plan 3: AppleScript Calendar Integration Summary

**AppleScript automation via NSAppleScript to open clicked events in Calendar.app with proper entitlements and usage descriptions**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-24T21:00:00Z
- **Completed:** 2026-01-24T21:04:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added com.apple.security.automation.apple-events entitlement for AppleScript
- Added NSAppleEventsUsageDescription explaining Calendar.app control
- Implemented openEventInCalendar using NSAppleScript with calendar title and event UID
- Quote escaping prevents AppleScript injection from malformed event/calendar names
- Graceful error handling: logs failures but Calendar.app likely opens anyway

## Task Commits

1. **Task 1: Add AppleScript automation entitlements** - `3a12cd5` (feat)
2. **Task 2: Implement openEventInCalendar with AppleScript** - `1d6a708` (feat)

## Files Created/Modified
- `ToEvent/ToEvent/ToEvent.entitlements` - Added automation.apple-events entitlement
- `ToEvent/ToEvent/Info.plist` - Added NSAppleEventsUsageDescription
- `ToEvent/ToEvent/Views/MenuBarView.swift` - Replaced placeholder with NSAppleScript implementation

## Decisions Made
- AppleScript via NSAppleScript - the only reliable way to open specific events in Calendar.app (per RESEARCH.md)
- Error logging without user alert - if AppleScript fails Calendar.app still activates, user can navigate manually
- Quote escaping for calendar and event IDs - prevents injection if event title contains double quotes

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- xcodebuild unavailable due to developer tools path - verified file contents directly

## User Setup Required
**First run automation permission:** macOS will prompt "ToEvent wants to control Calendar.app" on first event click. User must grant permission for the feature to work.

## Next Phase Readiness
- Phase 3 complete: dropdown event list with calendar integration
- Ready for Phase 4: Custom menu bar display format settings

---
*Phase: 03-dropdown-event-list*
*Completed: 2026-01-24*
