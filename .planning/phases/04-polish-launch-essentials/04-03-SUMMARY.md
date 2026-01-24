---
phase: 04-polish-launch-essentials
plan: 03
subsystem: settings-advanced
tags: [urgency, thresholds, fetch-interval, battery, settings]

dependencies:
  requires:
    - 02-01 (UrgencyLevel enum)
    - 03-01 (CalendarService refresh)
  provides:
    - Configurable urgency thresholds
    - Configurable calendar fetch interval
    - Configurable max events display
    - Battery-optimized background fetch
  affects:
    - Future performance tuning plans

tech-stack:
  added: []
  patterns:
    - NSBackgroundActivityScheduler for energy-efficient background tasks

key-files:
  created:
    - ToEvent/ToEvent/Views/Settings/AdvancedSettingsView.swift
  modified:
    - ToEvent/ToEvent/Utilities/UrgencyLevel.swift
    - ToEvent/ToEvent/State/AppState.swift
    - ToEvent/ToEvent/Services/CalendarService.swift
    - ToEvent/ToEvent/Views/EventListView.swift
    - ToEvent/ToEvent/ToEventApp.swift
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - "UrgencyThresholds struct with imminent/soon/approaching values"
  - "NSBackgroundActivityScheduler with 25% tolerance for battery optimization"
  - "Stepper controls with validation for threshold ordering"
  - "limitedEvents computed property to respect maxEventsToShow"

metrics:
  duration: 4m
  completed: 2026-01-24
---

# Phase 04 Plan 03: Advanced Settings Summary

**One-liner:** UrgencyThresholds struct with Stepper UI, NSBackgroundActivityScheduler for configurable fetch, maxEventsToShow limiting dropdown display.

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 6a34bd0 | feat | add configurable urgency thresholds |
| 8c9976e | feat | add fetch interval and event count settings |
| c5b312a | feat | create AdvancedSettingsView and register in app |

## Implementation Details

### Task 1: Configurable Urgency Thresholds

Added UrgencyThresholds struct to UrgencyLevel.swift:
```swift
struct UrgencyThresholds: Equatable {
    var imminent: TimeInterval    // default 900 (15 min)
    var soon: TimeInterval        // default 1800 (30 min)
    var approaching: TimeInterval // default 3600 (1 hour)

    static let `default` = UrgencyThresholds(imminent: 900, soon: 1800, approaching: 3600)
    var isValid: Bool { imminent < soon && soon < approaching }
}
```

Updated UrgencyLevel.from() to accept thresholds parameter:
- Original single-parameter method preserved for compatibility
- New method accepts thresholds for configurable behavior

AppState.urgencyThresholds persists to UserDefaults (3 separate keys for each value).

### Task 2: Fetch Interval and Event Count

AppState properties:
- `fetchInterval`: TimeInterval (default 300 seconds / 5 minutes)
- `maxEventsToShow`: Int (default 10)

CalendarService background fetch:
- NSBackgroundActivityScheduler with `repeats = true`
- 25% tolerance (`interval * 0.25`) for battery optimization
- `qualityOfService = .utility`
- Defers on low battery via `shouldDefer`

EventListView limits:
- `limitedEvents` computed property uses `Array(appState.events.prefix(appState.maxEventsToShow))`
- Applied before day/type filtering

### Task 3: AdvancedSettingsView

Three settings sections:
1. **Urgency Thresholds**: Steppers for imminent/soon/approaching with validation ranges
2. **Calendar Sync**: Picker for fetch interval (1m to 30m options)
3. **Event List**: Picker for max events (5, 10, 15, 20, 25)

Features:
- Range validation prevents invalid threshold ordering
- "Reset to Defaults" button
- Battery warning note for fetch interval

## Deviations from Plan

None - plan executed exactly as written.

## Success Criteria Status

- [x] CUST-03: Urgency color thresholds configurable
- [x] CUST-05: Calendar fetch interval configurable
- [x] CUST-06: Number of events configurable
- [x] SYST-05: Battery optimization via NSBackgroundActivityScheduler

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Separate UserDefaults keys per threshold | Allows partial updates without serialization |
| NSBackgroundActivityScheduler over Timer | System-managed, respects battery state |
| 25% tolerance | Balance between responsiveness and battery |
| Stepper with 60s step | Matches intuitive "minutes" mental model |

## Next Phase Readiness

- All settings persist and take effect immediately
- Background fetch respects system battery state
- Ready for Phase 4 completion
