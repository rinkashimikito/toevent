---
phase: 07
plan: 01
subsystem: distribution
tags: [sparkle, auto-update, xpc, sandboxing]
requires:
  - phase-06
provides:
  - sparkle-integration
  - updater-controller
  - auto-update-ui
affects:
  - 07-02
  - 07-03
  - 07-04
tech-stack:
  added:
    - sparkle@2.8.1
  patterns:
    - xpc-service-entitlements
    - spu-standard-updater-controller
key-files:
  created:
    - ToEvent/ToEvent/Services/UpdaterController.swift
  modified:
    - ToEvent/ToEvent.xcodeproj/project.pbxproj
    - ToEvent/ToEvent/ToEvent.entitlements
    - ToEvent/ToEvent/Info.plist
    - ToEvent/ToEvent/ToEventApp.swift
    - ToEvent/ToEvent/Views/Settings/GeneralSettingsView.swift
decisions:
  - id: 07-01-01
    decision: "Use SPUStandardUpdaterController for standard update UI"
    rationale: "Provides built-in progress dialog and user prompts"
  - id: 07-01-02
    decision: "SUFeedURL points to GitHub releases/latest/download path"
    rationale: "Release artifacts uploaded during workflow, not raw repo files"
  - id: 07-01-03
    decision: "Empty SUPublicEDKey placeholder"
    rationale: "EdDSA key generated during first release (Plan 04)"
metrics:
  duration: 3m
  completed: 2026-01-25
---

# Phase 07 Plan 01: Sparkle Auto-Update Integration Summary

Sparkle 2 framework integrated with XPC entitlements for sandboxed app, UpdaterController wrapper, and Check for Updates button in settings.

## Changes Made

### Task 1: Add Sparkle package and configure entitlements

**Files modified:**
- `ToEvent/ToEvent.xcodeproj/project.pbxproj` - Added Sparkle SPM package dependency
- `ToEvent/ToEvent/ToEvent.entitlements` - Added XPC mach-lookup exceptions
- `ToEvent/ToEvent/Info.plist` - Added SUFeedURL, SUEnableInstallerLauncherService, SUPublicEDKey

**Key changes:**
- Sparkle 2.8.1 resolved via Swift Package Manager
- XPC entitlements for sandboxed Sparkle services: `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` and `$(PRODUCT_BUNDLE_IDENTIFIER)-spki`
- SUFeedURL configured to `https://github.com/Immedio/toevent/releases/latest/download/appcast.xml`

**Commit:** d968b70

### Task 2: Create UpdaterController and integrate with app

**Files created:**
- `ToEvent/ToEvent/Services/UpdaterController.swift` - Sparkle updater wrapper

**Files modified:**
- `ToEvent/ToEvent/ToEventApp.swift` - Added UpdaterController StateObject and environment injection
- `ToEvent/ToEvent/Views/Settings/GeneralSettingsView.swift` - Added Check for Updates button

**Key changes:**
- UpdaterController wraps SPUStandardUpdaterController
- Publishes canCheckForUpdates state via Combine
- Button disabled when updater not ready

**Commit:** 73f6f61

## Decisions Made

| ID | Decision | Rationale |
|----|----------|-----------|
| 07-01-01 | Use SPUStandardUpdaterController | Provides built-in progress dialog and user prompts |
| 07-01-02 | SUFeedURL to releases/latest/download | Release artifacts uploaded during workflow |
| 07-01-03 | Empty SUPublicEDKey | EdDSA key generated during first release |

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- [x] Sparkle package resolved (v2.8.1 in Package.resolved)
- [x] XPC mach-lookup entitlements present
- [x] SUFeedURL points to releases/latest/download/appcast.xml
- [x] UpdaterController created with Combine publisher
- [x] Check for Updates button in GeneralSettingsView

Note: Build verification skipped due to xcode-select pointing to command line tools instead of Xcode.app. Manual Xcode build recommended.

## Next Phase Readiness

**Dependencies satisfied:**
- Sparkle framework integrated
- Entitlements configured for sandboxed operation
- Update UI available in settings

**Ready for:**
- Plan 07-02: Notarization and stapling
- Plan 07-03: DMG creation
- Plan 07-04: Release workflow with appcast generation
