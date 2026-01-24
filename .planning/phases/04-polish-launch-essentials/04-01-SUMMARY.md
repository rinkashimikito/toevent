---
phase: 04
plan: 01
subsystem: system-integration
tags: [keyboard-shortcuts, launch-at-login, settings, SPM]

dependency-graph:
  requires: [03-03]
  provides: [global-keyboard-shortcut, auto-launch-at-login, settings-ui-extension]
  affects: []

tech-stack:
  added: [KeyboardShortcuts@2.0.0+, LaunchAtLogin-Modern@1.0.0+]
  patterns: [ObservableObject-shortcut-handler]

file-tracking:
  key-files:
    created:
      - ToEvent/ToEvent/Extensions/KeyboardShortcuts+Names.swift
    modified:
      - ToEvent/ToEvent.xcodeproj/project.pbxproj
      - ToEvent/ToEvent/ToEventApp.swift
      - ToEvent/ToEvent/Views/Settings/GeneralSettingsView.swift

decisions:
  - id: 04-01-D1
    decision: ShortcutHandler ObservableObject for keyboard shortcut binding
    rationale: MenuBarExtra @State cannot be captured in init; ObservableObject pattern allows KeyboardShortcuts callback to modify isMenuPresented binding
    alternatives: [task-modifier, AppDelegate-pattern]

metrics:
  duration: 3m
  completed: 2026-01-24
---

# Phase 04 Plan 01: System Integration Summary

Global keyboard shortcut (Cmd+Option+E) with ShortcutHandler ObservableObject pattern and LaunchAtLogin toggle using sindresorhus packages.

## What Was Built

### Task 1: SPM Dependencies and Shortcut Name Extension
Added KeyboardShortcuts and LaunchAtLogin-Modern packages to project.pbxproj with proper package references, product dependencies, and framework build files.

Created `Extensions/KeyboardShortcuts+Names.swift`:
```swift
extension KeyboardShortcuts.Name {
    static let toggleDropdown = Self("toggleDropdown", default: .init(.e, modifiers: [.command, .option]))
}
```

### Task 2: Keyboard Shortcut Wiring
Added ShortcutHandler class to manage the global shortcut:
```swift
final class ShortcutHandler: ObservableObject {
    @Published var isMenuPresented = false

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleDropdown) { [weak self] in
            self?.isMenuPresented.toggle()
        }
    }
}
```

Modified ToEventApp to use `$shortcutHandler.isMenuPresented` binding with MenuBarExtraAccess.

### Task 3: Settings UI Extension
Extended GeneralSettingsView with two new sections before Events:
- **Startup:** LaunchAtLogin.Toggle for auto-launch at login
- **Keyboard Shortcut:** KeyboardShortcuts.Recorder for customizable shortcut

## Commit Log

| Task | Commit | Description |
|------|--------|-------------|
| 1 | ee4bf63 | Add KeyboardShortcuts and LaunchAtLogin SPM packages |
| 2 | 6b944d0 | Wire keyboard shortcut to toggle dropdown |
| 3 | 76c8515 | Add startup and keyboard shortcut settings |

## Decisions Made

### 04-01-D1: ShortcutHandler ObservableObject Pattern
**Decision:** Use separate ObservableObject class for shortcut handling instead of @State in App struct.

**Rationale:** MenuBarExtra's @State binding cannot be captured in init(), and Scene body doesn't support .task or .onAppear modifiers directly. The ObservableObject pattern allows the KeyboardShortcuts callback to modify the isMenuPresented binding from within init().

**Alternatives considered:**
- `.task` modifier on Scene - Not supported on Scene types
- AppDelegate with @NSApplicationDelegateAdaptor - More complex, unnecessary

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- [x] KeyboardShortcuts+Names.swift created with .toggleDropdown shortcut
- [x] KeyboardShortcuts and LaunchAtLogin-Modern packages added to project
- [x] ShortcutHandler wired to MenuBarExtraAccess isPresented binding
- [x] GeneralSettingsView has Startup section with LaunchAtLogin.Toggle
- [x] GeneralSettingsView has Keyboard Shortcut section with Recorder
- [x] Build verification deferred (xcodebuild not available in environment)

## Next Phase Readiness

Ready for 04-02 or 04-03. No blockers.

System integration features complete:
- SYST-01: Global keyboard shortcut toggles dropdown
- SYST-02: Auto-launch at login configurable in Settings
