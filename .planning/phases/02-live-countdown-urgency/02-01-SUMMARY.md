---
phase: 02-live-countdown-urgency
plan: 01
subsystem: countdown-infrastructure
tags: [swift, urgency, datetime, system-state, spm]

dependency-graph:
  requires: [01-core-menu-bar]
  provides: [urgency-level-enum, hybrid-countdown-formatter, screen-lock-detection]
  affects: [02-02-plan, 04-configuration]

tech-stack:
  added: [MenuBarExtraAccess]
  patterns: [singleton-service, distributed-notification-observer]

key-files:
  created:
    - ToEvent/ToEvent/Utilities/UrgencyLevel.swift
    - ToEvent/ToEvent/Services/SystemStateService.swift
  modified:
    - ToEvent/ToEvent/Utilities/DateFormatters.swift
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - id: urgency-thresholds
    choice: "15m/30m/60m for imminent/soon/approaching"
    reason: "Matches typical meeting prep times - 15m for final prep, 30m for context switching, 1h for planning"
  - id: seconds-threshold
    choice: "Show seconds when under 5 minutes"
    reason: "Balances precision needs with visual calm - seconds only when urgency is clear"
  - id: wake-as-unlock
    choice: "Treat system wake as potential unlock"
    reason: "Edge case handling - unlock notification may not fire on wake, safer to resume timer"

metrics:
  duration: 3m
  completed: 2026-01-24
---

# Phase 2 Plan 1: Countdown Infrastructure Summary

Foundation utilities for urgency-based countdown display with MenuBarExtraAccess dependency, UrgencyLevel enum, hybrid time formatter, and screen lock detection service.

## What Was Built

### Task 1: MenuBarExtraAccess Package Dependency
Added Swift Package Manager dependency for MenuBarExtraAccess (https://github.com/orchetect/MenuBarExtraAccess) to enable colored text in menu bar via NSStatusItem.button.attributedTitle access. This is required because SwiftUI MenuBarExtra ignores foregroundColor modifiers.

### Task 2: UrgencyLevel Enum and Hybrid Formatter
Created `UrgencyLevel.swift` with five levels:
- `.normal` (>1 hour) - system label color
- `.approaching` (<=1 hour) - yellow
- `.soon` (<=30 minutes) - orange
- `.imminent` (<=15 minutes) - red
- `.now` (event started) - red

Extended `DateFormatters.swift` with:
- `formatHybridCountdown(until:from:)` - adaptive format showing seconds when under 5 minutes
  - Examples: "2h 15m", "45m", "4m 32s", "28s", "Now"
- `shouldShowSeconds(until:from:)` - returns true when interval < 300 seconds for adaptive timer scheduling

### Task 3: SystemStateService
Created singleton service following CalendarService pattern:
- Observes `com.apple.screenIsLocked` and `com.apple.screenIsUnlocked` via DistributedNotificationCenter
- Observes `NSWorkspace.didWakeNotification` to handle edge case where unlock doesn't fire on wake
- Publishes `isScreenLocked` state that AppState will use to pause/resume timer updates

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 86e3ab0 | chore | Add MenuBarExtraAccess package dependency |
| 183f5e6 | feat | Add UrgencyLevel enum and hybrid countdown formatter |
| ae86ea6 | feat | Add SystemStateService for screen lock detection |

## Deviations from Plan

None - plan executed exactly as written.

## Technical Notes

- UrgencyLevel implements `Comparable` for threshold comparisons (e.g., `level >= .soon` for iconFilled)
- All NSColor values use system colors (.systemYellow, .systemOrange, .systemRed) for automatic dark/light mode adaptation
- SystemStateService uses `[weak self]` in notification closures to avoid retain cycles
- Xcode project was modified directly (not via xcodebuild) since xcode-select points to CommandLineTools

## Next Phase Readiness

Plan 02-02 can now implement:
- Colored menu bar text using MenuBarExtraAccess + UrgencyLevel.color
- Adaptive timer updates using shouldShowSeconds
- Timer pause/resume using SystemStateService.isScreenLocked

**Blockers:** None
**Concerns:** None
