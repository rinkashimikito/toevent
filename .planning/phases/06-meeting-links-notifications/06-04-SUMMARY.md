---
phase: 06-meeting-links-notifications
plan: 04
subsystem: travel-time-conflicts
tags: [mapkit, mkdirections, travel-time, conflicts, ui]

dependency-graph:
  requires: [06-01]
  provides: [travel-time-service, conflict-detection, travel-ui]
  affects: [06-05, 06-06]

tech-stack:
  added: []
  patterns: [mapkit-directions, geocoding, conflict-detection]

key-files:
  created:
    - ToEvent/ToEvent/Services/TravelTimeService.swift
    - ToEvent/ToEvent/Extensions/Array+Conflicts.swift
  modified:
    - ToEvent/ToEvent/State/AppState.swift
    - ToEvent/ToEvent/Views/EventRowView.swift
    - ToEvent/ToEvent/Views/EventDetailView.swift
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - key: travel-time-cache
    choice: "In-memory dictionary cache keyed by address"
    context: "Avoid repeated MKDirections API calls"
  - key: leave-time-buffer
    choice: "5-minute buffer added to travel time"
    context: "Account for parking, walking to venue"
  - key: conflict-detection
    choice: "Exclude all-day events from conflict checks"
    context: "All-day events don't create scheduling conflicts"

metrics:
  duration: 5m
  completed: 2026-01-25
---

# Phase 06 Plan 04: Travel Time + Conflict Detection Summary

MKDirections-based travel time with caching and overlapping event detection with UI warnings.

## What Was Built

### TravelTimeService (new)

- Singleton service for travel time calculation
- CLGeocoder for address to coordinates conversion
- MKDirections for ETA from current location
- In-memory cache to avoid repeated API calls
- calculateLeaveTime() adds 5-minute buffer for parking/walking
- formatTravelTime() for display (e.g., "25 min" or "1h 15min")

### Array+Conflicts Extension (new)

- `conflicts` property returns all overlapping event pairs
- `conflictingEventIDs` returns Set of event IDs with conflicts
- `hasConflict(_:)` checks if specific event has overlap
- Excludes all-day events from conflict detection

### AppState Changes

- `conflictingEventIDs` computed property using Array+Conflicts
- `hasConflict(_:)` method for quick lookup in views

### EventRowView Changes

- Orange warning triangle icon for events with conflicts
- Tooltip "Overlaps with another event" on hover
- Icon appears between calendar dot and title

### EventDetailView Changes

- Travel section with car icon after location
- Async calculation via .task modifier
- Loading indicator during calculation
- Shows travel duration and "Leave by X:XX" time
- Falls back to "Travel time unavailable" on failure

## Commits

| Hash | Description |
|------|-------------|
| 7b95f74 | feat(06-04): add TravelTimeService for ETA calculation |
| 91289fd | feat(06-04): add Array+Conflicts extension for overlap detection |
| ebade2a | feat(06-04): add conflict tracking and UI indicator |
| f37456c | feat(06-04): display travel time and leave time in EventDetailView |

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

Ready for:
- 06-05: Notification scheduling (has TravelTimeService for leave-time alerts)
- 06-06: Settings UI for notification preferences

No blockers.
