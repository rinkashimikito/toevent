---
phase: 01-core-menu-bar-local-calendar
plan: 03
status: complete
started: 2026-01-24
completed: 2026-01-24
---

## Summary

Added calendar settings using sindresorhus/Settings package with calendar selection toggles and general settings for lookahead configuration.

## Deliverables

| Artifact | Purpose |
|----------|---------|
| ToEvent/Views/Settings/CalendarSettingsView.swift | Calendar selection UI with toggles per calendar |
| ToEvent/Views/Settings/GeneralSettingsView.swift | General settings with lookahead picker |
| ToEvent/Utilities/SettingsTypes.swift | Typealiases to avoid SwiftUI.Settings ambiguity |

## Commits

| Hash | Message |
|------|---------|
| 8443508 | feat(01-03): add sindresorhus/Settings and create settings views |
| 7525855 | feat(01-03): integrate Settings into app and add access point |
| 6b06874 | fix: resolve Settings type ambiguity with SwiftUI |
| a8deaf2 | fix: add SettingsTypes.swift to Xcode project |
| 6473034 | fix(01-03): resolve Sendable closure capture issue |
| 3bdece1 | feat(01-03): add debug info and reset button to dropdown |
| d9cc85f | fix(01-03): show intro when permission not granted |
| d660a16 | fix(01-03): make menuBarTitle a Published property |
| d2574e5 | fix(01-03): use ObservedObject wrapper for menu bar label |
| 18f166b | fix(01-03): cleanup debug code and finalize phase 1 |

## Issues Encountered

1. **Settings type ambiguity**: SwiftUI and sindresorhus/Settings both export `Settings` type. Fixed with typealiases in SettingsTypes.swift.
2. **Sendable closure capture**: @MainActor caused issues with async callbacks. Fixed by using @unchecked Sendable.
3. **MenuBarExtra label not updating**: SwiftUI doesn't observe state changes in MenuBarExtra labels properly. Fixed with separate MenuBarLabel view using @ObservedObject.
4. **Permission flow**: Added check to show intro when permission not granted, even if hasCompletedIntro is true.

## Verification

Human verification completed - user confirmed:
- Menu bar shows calendar icon + event title + relative time
- Dropdown shows next event
- Settings accessible
- Calendar permissions working (33 calendars detected)
