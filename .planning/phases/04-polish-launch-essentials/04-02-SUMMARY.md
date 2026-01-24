---
phase: 04-polish-launch-essentials
plan: 02
title: Display Settings
subsystem: settings
tags: [display, privacy, time-format, natural-language]

dependency_graph:
  requires: [03-02]
  provides: [display-customization, privacy-mode, time-format-options]
  affects: []

tech_stack:
  added: []
  patterns: [settings-pane, user-preferences]

key_files:
  created:
    - ToEvent/ToEvent/Views/Settings/DisplaySettingsView.swift
  modified:
    - ToEvent/ToEvent/State/AppState.swift
    - ToEvent/ToEvent/Utilities/DateFormatters.swift
    - ToEvent/ToEvent/Views/EventRowView.swift
    - ToEvent/ToEvent/ToEventApp.swift
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - id: DISP-01
    choice: "TimeDisplayFormat enum for format selection"
    rationale: "Type-safe selection with CaseIterable for Picker iteration"
  - id: DISP-02
    choice: "Natural language thresholds at fixed intervals"
    rationale: "Human-friendly time descriptions (soon, shortly, in under an hour)"
  - id: DISP-03
    choice: "Privacy mode at display layer only"
    rationale: "Titles masked in UI, underlying data unchanged for functionality"

metrics:
  duration: 5m
  completed: 2026-01-24
---

# Phase 04 Plan 02: Display Settings Summary

TimeDisplayFormat enum with countdown/absolute/both modes, formatNaturalLanguage with tiered thresholds, privacy mode masking titles in menu bar and dropdown.

## What Was Built

### Task 1: Display Settings Properties in AppState
- Added `TimeDisplayFormat` enum with countdown, absolute, both options
- Added `timeDisplayFormat`, `useNaturalLanguage`, `privacyMode` @Published properties
- All settings persist via UserDefaults
- Updated `updateMenuBarTitle()` to respect privacy mode
- Added `formatTimeForMenuBar()` for format-aware time display

### Task 2: Natural Language and Absolute Time Formatters
- Added `formatAbsoluteTime()` using DateFormatter.timeStyle = .short
- Added `formatNaturalLanguage()` with human-friendly thresholds:
  - < 1 min: "now"
  - < 5 min: "very soon"
  - < 15 min: "soon"
  - < 30 min: "shortly"
  - < 1 hour: "in under an hour"
  - < 2 hours: "in about an hour"
  - 2+ hours: "in N hours"

### Task 3: DisplaySettingsView and EventRowView Updates
- Created `DisplaySettingsView` with time format picker and privacy toggle
- Updated `EventRowView` to use `appState.timeDisplayFormat` and `privacyMode`
- Registered DisplaySettingsView in Settings scene between General and Calendar
- Added file to Xcode project

## Commits

| Hash | Message |
|------|---------|
| a5e9da8 | feat(04-02): add display settings properties to AppState |
| 4b8df23 | feat(04-02): add natural language and absolute time formatters |
| 03b11b2 | feat(04-02): create DisplaySettingsView and update EventRowView |

## Deviations from Plan

None - plan executed exactly as written.

## Success Criteria Verification

- [x] CUST-04: Time display format configurable (countdown/absolute/both)
- [x] MENU-06: Natural language option available
- [x] MENU-07: Privacy mode hides event titles everywhere
- [x] All settings persist across app restarts
- [x] UI follows existing SettingsSection pattern

## Next Phase Readiness

**Dependencies satisfied:** Display customization complete.

**Blockers:** None.

**Notes:** Natural language mode disabled when absolute time is selected (countdown component not shown).
