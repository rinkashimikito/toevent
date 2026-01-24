---
phase: 07-distribution-notarization
plan: 03
subsystem: user-experience
tags: [changelog, whats-new, version-tracking]

dependency-graph:
  requires: [07-01]
  provides: [whats-new-screen, changelog]
  affects: []

tech-stack:
  added: []
  patterns: [version-comparison, userdefaults-persistence]

key-files:
  created:
    - ToEvent/ToEvent/Utilities/WhatsNewCheck.swift
    - ToEvent/ToEvent/Views/WhatsNewView.swift
    - CHANGELOG.md
  modified:
    - ToEvent/ToEvent/ToEventApp.swift
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - id: whats-new-first-launch
    choice: "Skip What's New on first launch"
    reason: "No previous version to compare - user hasn't upgraded"
  - id: changelog-hardcoded
    choice: "Hardcode changelog content in WhatsNewView"
    reason: "Simpler than parsing CHANGELOG.md at runtime"

metrics:
  duration: 3m
  completed: 2026-01-25
---

# Phase 07 Plan 03: What's New Screen Summary

Version change detection with changelog display on first launch after update using UserDefaults version tracking.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create WhatsNewCheck utility and WhatsNewView | 578cac4 | WhatsNewCheck.swift, WhatsNewView.swift |
| 2 | Integrate What's New with app and create CHANGELOG | 658506b | ToEventApp.swift, CHANGELOG.md |

## Implementation Details

### WhatsNewCheck Utility
- Stores `lastSeenVersion` in UserDefaults
- `shouldShowWhatsNew()` compares current vs stored version
- First launch (nil stored) marks as seen and returns false
- Returns true only when version differs (upgrade scenario)
- `markAsSeen()` called when user dismisses dialog

### WhatsNewView
- Modal sheet with version header
- ScrollView with changelog items
- ChangelogSection component for feature groupings
- Continue button dismisses and marks version seen
- Fixed 400pt width for consistent presentation

### App Integration
- @State showWhatsNew triggers sheet presentation
- Checks shouldShowWhatsNew() on MenuBarExtra content appear
- Sheet presented from Group wrapper around menu content

### CHANGELOG.md
- Keep a Changelog format
- Semantic versioning adherence
- 0.9.0 initial release with all phase features documented

## Verification Results

- [x] WhatsNewCheck correctly identifies version changes
- [x] WhatsNewView displays with changelog items
- [x] Continue button dismisses and marks version seen
- [x] App doesn't show What's New on fresh install
- [x] App shows What's New when upgrading from previous version
- [x] CHANGELOG.md has 0.9.0 release notes

## Deviations from Plan

None - plan executed exactly as written.

## Commits

1. `578cac4` - feat(07-03): add WhatsNewCheck utility and WhatsNewView
2. `658506b` - feat(07-03): integrate What's New sheet and add CHANGELOG

## Next Phase Readiness

What's New infrastructure complete. Future releases:
1. Update WhatsNewView content for each version
2. Add new sections to CHANGELOG.md
3. Version tracking handles upgrade detection automatically
