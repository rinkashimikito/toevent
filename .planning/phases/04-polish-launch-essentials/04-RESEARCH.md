# Phase 4: Polish + Launch Essentials - Research

**Researched:** 2026-01-24
**Domain:** macOS system integration (keyboard shortcuts, launch at login, battery optimization, settings UI)
**Confidence:** HIGH (well-documented sindresorhus packages, Apple APIs verified)

## Summary

Phase 4 requires implementing system-level macOS features: global keyboard shortcuts, launch at login, and expanded settings. The sindresorhus ecosystem provides battle-tested solutions that integrate with the existing codebase: KeyboardShortcuts for global hotkeys, LaunchAtLogin-Modern for login items (both macOS 13+). The existing Settings package can be extended with new panes.

Battery optimization is partially addressed by existing code (screen lock detection, adaptive timer intervals). Additional optimization through configurable fetch intervals and NSBackgroundActivityScheduler can reduce energy impact further.

**Primary recommendation:** Use sindresorhus/KeyboardShortcuts + sindresorhus/LaunchAtLogin-Modern packages. Extend existing Settings panes. Add configurable refresh intervals with NSBackgroundActivityScheduler for calendar fetches.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| sindresorhus/KeyboardShortcuts | Latest | User-customizable global keyboard shortcuts | Mac App Store safe, SwiftUI UI included, works with NSMenu open |
| sindresorhus/LaunchAtLogin-Modern | Latest | Launch at login toggle | Uses SMAppService (macOS 13+), SwiftUI toggle included |
| sindresorhus/Settings | 3.1.0+ | Settings window | Already in use, extends naturally |
| MenuBarExtraAccess | 1.0.0+ | Programmatic menu toggle | Already in use, isPresented binding for shortcut |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ServiceManagement (SMAppService) | Built-in | Login item registration | LaunchAtLogin uses internally |
| NSBackgroundActivityScheduler | Built-in | Energy-efficient background tasks | Configurable calendar fetch interval |
| ProcessInfo.beginActivity | Built-in | Prevent App Nap during critical work | Short-term activity protection |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| KeyboardShortcuts | soffes/HotKey | HotKey is simpler but no UI recorder component |
| LaunchAtLogin-Modern | Raw SMAppService | Direct API but more code, no SwiftUI toggle |
| sindresorhus/Defaults | Raw UserDefaults | Already using raw UserDefaults, migration cost vs benefit unclear |

**Installation:**
```bash
# Add to Xcode SPM:
https://github.com/sindresorhus/KeyboardShortcuts
https://github.com/sindresorhus/LaunchAtLogin-Modern
```

## Architecture Patterns

### Recommended Project Structure
```
ToEvent/
├── State/
│   └── AppState.swift          # Add settings properties
├── Services/
│   ├── CalendarService.swift   # Add configurable fetch interval
│   └── SystemStateService.swift # Existing
├── Views/
│   ├── Settings/
│   │   ├── GeneralSettingsView.swift  # Extend with shortcuts, launch
│   │   ├── CalendarSettingsView.swift # Existing
│   │   ├── DisplaySettingsView.swift  # NEW: time format, privacy mode
│   │   └── AdvancedSettingsView.swift # NEW: fetch interval, battery
│   └── ...
├── Utilities/
│   ├── UrgencyLevel.swift      # Add configurable thresholds
│   └── ...
└── Extensions/
    └── KeyboardShortcuts+Names.swift # NEW: shortcut name definitions
```

### Pattern 1: KeyboardShortcuts Registration
**What:** Define shortcut names as static extension, add listener in App init
**When to use:** Global keyboard shortcut that toggles menu
**Example:**
```swift
// Source: https://github.com/sindresorhus/KeyboardShortcuts
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleDropdown = Self("toggleDropdown", default: .init(.e, modifiers: [.command, .option]))
}

// In ToEventApp.swift
@main
struct ToEventApp: App {
    @State private var isMenuPresented = false

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleDropdown) {
            isMenuPresented.toggle()
        }
    }

    var body: some Scene {
        MenuBarExtra { ... }
            .menuBarExtraAccess(isPresented: $isMenuPresented) { ... }
    }
}
```

### Pattern 2: LaunchAtLogin Toggle in Settings
**What:** Use LaunchAtLogin.Toggle() SwiftUI component in settings
**When to use:** Settings pane for auto-launch preference
**Example:**
```swift
// Source: https://github.com/sindresorhus/LaunchAtLogin-Modern
import LaunchAtLogin

struct GeneralSettingsView: View {
    var body: some View {
        SettingsContainer(contentWidth: 450) {
            SettingsSection(title: "Startup") {
                LaunchAtLogin.Toggle("Launch at login")
            }
        }
    }
}
```

### Pattern 3: KeyboardShortcuts Recorder in Settings
**What:** Let user customize the global shortcut
**When to use:** Settings pane for keyboard customization
**Example:**
```swift
// Source: https://github.com/sindresorhus/KeyboardShortcuts
import KeyboardShortcuts

struct GeneralSettingsView: View {
    var body: some View {
        SettingsContainer(contentWidth: 450) {
            SettingsSection(title: "Keyboard") {
                KeyboardShortcuts.Recorder("Toggle dropdown:", name: .toggleDropdown)
            }
        }
    }
}
```

### Pattern 4: Configurable Settings with Enum
**What:** Use enums for settings with predefined options
**When to use:** Time format display, natural language toggle
**Example:**
```swift
enum TimeDisplayFormat: String, CaseIterable, Identifiable {
    case countdown = "countdown"
    case absolute = "absolute"
    case both = "both"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .countdown: return "Countdown (5m 30s)"
        case .absolute: return "Absolute (2:30 PM)"
        case .both: return "Both (5m 30s - 2:30 PM)"
        }
    }
}

// In AppState
@Published var timeDisplayFormat: TimeDisplayFormat {
    didSet {
        UserDefaults.standard.set(timeDisplayFormat.rawValue, forKey: Keys.timeDisplayFormat)
    }
}
```

### Pattern 5: NSBackgroundActivityScheduler for Calendar Fetch
**What:** Schedule energy-efficient background calendar refreshes
**When to use:** Configurable fetch interval for battery optimization
**Example:**
```swift
// Source: Apple NSBackgroundActivityScheduler documentation
import Foundation

final class CalendarService {
    private var backgroundActivity: NSBackgroundActivityScheduler?

    func startBackgroundFetch(interval: TimeInterval) {
        stopBackgroundFetch()

        backgroundActivity = NSBackgroundActivityScheduler(identifier: "com.toevent.calendarFetch")
        backgroundActivity?.repeats = true
        backgroundActivity?.interval = interval
        backgroundActivity?.tolerance = interval * 0.25 // 25% tolerance for system flexibility
        backgroundActivity?.qualityOfService = .utility

        backgroundActivity?.schedule { [weak self] completion in
            if self?.backgroundActivity?.shouldDefer == true {
                completion(.deferred)
                return
            }

            DispatchQueue.main.async {
                self?.refreshEvents()
                completion(.finished)
            }
        }
    }

    func stopBackgroundFetch() {
        backgroundActivity?.invalidate()
        backgroundActivity = nil
    }
}
```

### Anti-Patterns to Avoid
- **Storing launch at login state locally:** Always read from SMAppService.mainApp.status - user can change in System Settings
- **Using Timer for background refresh:** NSBackgroundActivityScheduler is more energy-efficient, system-coordinated
- **Enabling launch at login by default:** Mac App Store requires explicit user action
- **Hard-coding urgency thresholds:** Make configurable, use Settings enum patterns

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Global keyboard shortcut | Carbon APIs directly | KeyboardShortcuts | Complex Carbon API, needs UI recorder |
| Launch at login | Raw SMAppService | LaunchAtLogin-Modern | Handles edge cases, provides toggle |
| Shortcut conflict detection | Manual system shortcut checking | KeyboardShortcuts.Recorder | Built-in conflict warning |
| Settings persistence | Custom UserDefaults wrappers | Existing raw UserDefaults pattern | Already working, minimal benefit to change |

**Key insight:** The sindresorhus packages are Mac App Store approved and used in production apps (Dato, Lungo, Plash). They handle edge cases and provide SwiftUI components that match the existing Settings integration pattern.

## Common Pitfalls

### Pitfall 1: Launch at Login State Drift
**What goes wrong:** UI shows "enabled" but user disabled in System Settings
**Why it happens:** Storing state locally instead of reading from SMAppService
**How to avoid:** Always read SMAppService.mainApp.status for current state
**Warning signs:** Toggle doesn't match System Settings > Login Items

### Pitfall 2: Keyboard Shortcut Blocked by NSMenu
**What goes wrong:** Shortcut doesn't work when menu bar dropdown is open
**Why it happens:** NSMenu blocks runloop during presentation
**How to avoid:** KeyboardShortcuts handles this if using .window style (which ToEvent uses)
**Warning signs:** Shortcut only works when dropdown is closed

### Pitfall 3: Battery Drain from Frequent Calendar Refresh
**What goes wrong:** High energy impact even when idle
**Why it happens:** Fixed-interval Timer refresh ignoring system state
**How to avoid:** Use NSBackgroundActivityScheduler with tolerance; honor screen lock state
**Warning signs:** Activity Monitor shows high "Energy Impact" when idle

### Pitfall 4: Settings Pane Overload
**What goes wrong:** Too many options in single settings pane, poor UX
**Why it happens:** Adding all new settings to GeneralSettingsView
**How to avoid:** Organize into logical panes: General (launch/keyboard), Display (format/privacy), Advanced (battery)
**Warning signs:** Settings window requires scrolling

### Pitfall 5: Privacy Mode Implementation Incomplete
**What goes wrong:** Event titles visible in menu bar even with privacy mode
**Why it happens:** Only hiding in dropdown, not in menu bar label
**How to avoid:** Privacy mode must affect: menuBarTitle, dropdown event list, potentially notifications
**Warning signs:** Event titles visible anywhere when privacy mode enabled

### Pitfall 6: Urgency Threshold Validation
**What goes wrong:** User sets invalid threshold combinations (imminent > soon)
**Why it happens:** No validation on threshold input
**How to avoid:** Validate thresholds are ordered: imminent < soon < approaching; use stepper bounds
**Warning signs:** Color coding appears inconsistent

## Code Examples

Verified patterns from official sources:

### Complete Settings Pane Addition
```swift
// Source: sindresorhus/Settings documentation
import SwiftUI
import Settings
import LaunchAtLogin
import KeyboardShortcuts

struct GeneralSettingsView: View {
    var body: some View {
        SettingsContainer(contentWidth: 450) {
            SettingsSection(title: "Startup") {
                LaunchAtLogin.Toggle("Launch at login")
            }

            SettingsSection(title: "Keyboard Shortcut") {
                KeyboardShortcuts.Recorder("Toggle dropdown:", name: .toggleDropdown)
                    .padding(.leading, -8) // Align with other controls
            }
        }
    }
}

extension GeneralSettingsView {
    static let pane: SettingsPane = SettingsPane(
        identifier: SettingsPaneIdentifier("general"),
        title: "General",
        toolbarIcon: NSImage(systemSymbolName: "gear", accessibilityDescription: "General")!
    ) {
        GeneralSettingsView()
    }
}
```

### Display Settings with Enums
```swift
// Source: Custom implementation following AppState pattern
struct DisplaySettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsContainer(contentWidth: 450) {
            SettingsSection(title: "Time Display") {
                Picker("Format:", selection: $appState.timeDisplayFormat) {
                    ForEach(TimeDisplayFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Use natural language (\"soon\" vs \"in 5min\")", isOn: $appState.useNaturalLanguage)
            }

            SettingsSection(title: "Privacy") {
                Toggle("Hide event titles", isOn: $appState.privacyMode)
                    .help("Shows \"Event\" instead of actual title")
            }
        }
    }
}
```

### Keyboard Shortcut Toggle with MenuBarExtraAccess
```swift
// Source: MenuBarExtraAccess + KeyboardShortcuts integration
import SwiftUI
import KeyboardShortcuts
import MenuBarExtraAccess

@main
struct ToEventApp: App {
    @StateObject private var appState = AppState()
    @State private var isMenuPresented = false
    @State private var statusItem: NSStatusItem?

    init() {
        // Register keyboard shortcut listener
        KeyboardShortcuts.onKeyUp(for: .toggleDropdown) { [self] in
            isMenuPresented.toggle()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            // content
        } label: {
            // label
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $isMenuPresented) { item in
            statusItem = item
        }
    }
}
```

### Configurable Urgency Thresholds
```swift
// Source: Extension of existing UrgencyLevel pattern
enum UrgencyLevel: Comparable {
    case normal
    case approaching
    case soon
    case imminent
    case now

    static func from(secondsRemaining: TimeInterval, thresholds: UrgencyThresholds) -> UrgencyLevel {
        switch secondsRemaining {
        case ...0: return .now
        case 0..<thresholds.imminent: return .imminent
        case thresholds.imminent..<thresholds.soon: return .soon
        case thresholds.soon..<thresholds.approaching: return .approaching
        default: return .normal
        }
    }
}

struct UrgencyThresholds {
    var imminent: TimeInterval = 900      // 15 min
    var soon: TimeInterval = 1800         // 30 min
    var approaching: TimeInterval = 3600  // 1 hour

    static let `default` = UrgencyThresholds()
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SMLoginItemSetEnabled | SMAppService.mainApp | macOS 13 | Simpler API, no helper app needed |
| Carbon HIToolbox hotkeys | KeyboardShortcuts wrapper | Ongoing | SwiftUI integration, UI recorder |
| Timer for background refresh | NSBackgroundActivityScheduler | macOS 10.10+ | System-coordinated, battery efficient |
| Fixed refresh intervals | Adaptive + configurable | Best practice | User control over battery impact |

**Deprecated/outdated:**
- SMLoginItemSetEnabled: Use SMAppService on macOS 13+
- LSSharedFileListInsertItemURL: Removed entirely
- Manual Carbon hotkey registration: Use KeyboardShortcuts wrapper

## Open Questions

Things that couldn't be fully resolved:

1. **KeyboardShortcuts + @State isMenuPresented synchronization**
   - What we know: KeyboardShortcuts listener runs on main thread, isMenuPresented is @State
   - What's unclear: Whether SwiftUI state update from listener will reliably toggle MenuBarExtraAccess binding
   - Recommendation: Test directly; may need DispatchQueue.main.async wrapper

2. **NSBackgroundActivityScheduler vs EventKit EKEventStoreChanged**
   - What we know: CalendarService already observes EKEventStoreChanged for external changes
   - What's unclear: Whether NSBackgroundActivityScheduler adds value over current notification-based approach
   - Recommendation: Keep EKEventStoreChanged for external changes; add configurable interval for "staleness check" only

3. **Privacy mode scope**
   - What we know: Need to hide event titles
   - What's unclear: Should it also hide calendar names, meeting links, all-day event details?
   - Recommendation: Start with title only ("Event" placeholder), expand based on feedback

## Sources

### Primary (HIGH confidence)
- [sindresorhus/KeyboardShortcuts GitHub](https://github.com/sindresorhus/KeyboardShortcuts) - API, SwiftUI recorder
- [sindresorhus/LaunchAtLogin-Modern GitHub](https://github.com/sindresorhus/LaunchAtLogin-Modern) - macOS 13+ login items
- [sindresorhus/Settings GitHub](https://github.com/sindresorhus/Settings) - Settings pane patterns
- [MenuBarExtraAccess GitHub](https://github.com/orchetect/MenuBarExtraAccess) - isPresented binding
- [Apple SMAppService Documentation](https://developer.apple.com/documentation/servicemanagement/smappservice) - Login item API

### Secondary (MEDIUM confidence)
- [Apple NSBackgroundActivityScheduler Documentation](https://developer.apple.com/documentation/foundation/nsbackgroundactivityscheduler) - Background task scheduling
- [Apple Energy Efficiency Guide](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/index.html) - Timer optimization
- [nilcoalescing.com - Launch at Login](https://nilcoalescing.com/blog/LaunchAtLoginSetting/) - SMAppService implementation patterns

### Tertiary (LOW confidence)
- NSBackgroundActivityScheduler integration with menu bar apps - Needs validation with existing timer architecture
- KeyboardShortcuts + MenuBarExtraAccess binding sync - Needs testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - sindresorhus packages are production-tested, Mac App Store approved
- Architecture: HIGH - Follows existing codebase patterns (Settings, MenuBarExtraAccess)
- Pitfalls: MEDIUM - Based on documentation, some edge cases need validation
- Battery optimization: MEDIUM - NSBackgroundActivityScheduler pattern documented, integration needs testing

**Research date:** 2026-01-24
**Valid until:** ~60 days (stable APIs, sindresorhus packages actively maintained)
