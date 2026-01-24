# Phase 2: Live Countdown + Urgency - Research

**Researched:** 2026-01-24
**Domain:** SwiftUI timers, menu bar styling, system state detection
**Confidence:** MEDIUM (menu bar coloring requires AppKit bridge, verified patterns available)

## Summary

Phase 2 requires implementing real-time countdown display with urgency-based color coding. The key technical challenge is that SwiftUI's MenuBarExtra does not natively support colored text - achieving this requires accessing the underlying NSStatusItem via the MenuBarExtraAccess library or direct AppKit integration.

Timer updates should use SwiftUI's TimelineView with an adaptive schedule - 1-second updates when showing seconds precision, 60-second updates otherwise. Screen lock detection via DistributedNotificationCenter allows pausing updates to save battery.

**Primary recommendation:** Use MenuBarExtraAccess library to access NSStatusItem.button.attributedTitle for colored text. Implement custom TimelineSchedule for adaptive update frequency based on time remaining.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI TimelineView | Built-in (macOS 13+) | Time-based view updates | System-managed, battery-efficient |
| DistributedNotificationCenter | Built-in | Screen lock/unlock detection | Only reliable way to detect lock state |
| MenuBarExtraAccess | Latest | Access NSStatusItem from MenuBarExtra | Only way to get colored text in menu bar |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AppKit (NSAttributedString) | Built-in | Styled menu bar text | For urgency color coding |
| SF Symbols | 5.0+ | Icon variants (outline/filled) | Urgency icon states |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| MenuBarExtraAccess | Full AppKit NSStatusItem | More control, but loses SwiftUI integration |
| TimelineView | Timer.publish + onReceive | Manual lifecycle management, no system optimization |
| Custom schedule | Fixed periodic(1s) | Wastes battery when seconds not displayed |

**Installation:**
```bash
# Add to Package.swift or via Xcode SPM
https://github.com/orchetect/MenuBarExtraAccess
```

## Architecture Patterns

### Recommended Project Structure
```
ToEvent/
├── State/
│   └── AppState.swift          # Add urgency level, timer state
├── Services/
│   ├── CalendarService.swift   # Existing
│   └── SystemStateService.swift # NEW: Screen lock detection
├── Views/
│   ├── MenuBarLabel.swift      # Refactor for colored text
│   └── MenuBarView.swift       # Add urgency indicators
├── Utilities/
│   ├── DateFormatters.swift    # Extend for hybrid format
│   ├── UrgencyLevel.swift      # NEW: Enum for thresholds
│   └── AdaptiveSchedule.swift  # NEW: Custom TimelineSchedule
```

### Pattern 1: Adaptive TimelineSchedule
**What:** Custom schedule that adjusts update frequency based on time remaining
**When to use:** When showing countdown with variable precision (seconds vs minutes)
**Example:**
```swift
// Source: Custom implementation based on TimelineSchedule protocol
struct AdaptiveCountdownSchedule: TimelineSchedule {
    let eventDate: Date
    let secondsThreshold: TimeInterval = 300 // 5 minutes

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var current = startDate
        return AnyIterator {
            guard current < self.eventDate.addingTimeInterval(60) else { return nil }
            let distance = self.eventDate.timeIntervalSince(current)
            let interval: TimeInterval = distance <= self.secondsThreshold ? 1 : 60
            let entry = current
            current = current.addingTimeInterval(interval)
            return entry
        }
    }
}
```

### Pattern 2: NSStatusItem Color Bridge
**What:** Use MenuBarExtraAccess to set attributedTitle for colored text
**When to use:** For urgency color coding in menu bar
**Example:**
```swift
// Source: MenuBarExtraAccess documentation + NSAttributedString API
import MenuBarExtraAccess

MenuBarExtra {
    // content
} label: {
    MenuBarLabel(appState: appState)
}
.menuBarExtraStyle(.window)
.menuBarExtraAccess(isPresented: $isPresented) { statusItem in
    updateStatusItemColor(statusItem, urgency: appState.urgencyLevel)
}

func updateStatusItemColor(_ statusItem: NSStatusItem, urgency: UrgencyLevel) {
    let color: NSColor = switch urgency {
        case .normal: .labelColor
        case .approaching: .systemYellow  // 1h
        case .soon: .systemOrange         // 30m
        case .imminent: .systemRed        // 15m
    }

    let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: color,
        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    ]
    statusItem.button?.attributedTitle = NSAttributedString(
        string: appState.menuBarTitle,
        attributes: attributes
    )
}
```

### Pattern 3: Screen Lock Observer
**What:** Pause/resume timer on screen lock/unlock
**When to use:** Battery optimization
**Example:**
```swift
// Source: DistributedNotificationCenter API
final class SystemStateService: ObservableObject {
    @Published private(set) var isScreenLocked = false

    init() {
        let dnc = DistributedNotificationCenter.default()

        dnc.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = true
        }

        dnc.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = false
        }
    }
}
```

### Pattern 4: Urgency Level Enum
**What:** Centralized urgency threshold logic
**When to use:** Consistent threshold handling across views
**Example:**
```swift
enum UrgencyLevel: Comparable {
    case normal      // > 1 hour
    case approaching // <= 1 hour (yellow)
    case soon        // <= 30 minutes (orange)
    case imminent    // <= 15 minutes (red)
    case now         // event started

    static func from(secondsRemaining: TimeInterval) -> UrgencyLevel {
        switch secondsRemaining {
        case ...0: return .now
        case 0..<900: return .imminent      // 15 min
        case 900..<1800: return .soon       // 30 min
        case 1800..<3600: return .approaching // 1 hour
        default: return .normal
        }
    }

    var color: NSColor {
        switch self {
        case .normal: return .labelColor
        case .approaching: return .systemYellow
        case .soon: return .systemOrange
        case .imminent, .now: return .systemRed
        }
    }
}
```

### Anti-Patterns to Avoid
- **Using Timer.publish for menu bar updates:** TimelineView is system-optimized; Timer runs continuously even when not needed
- **Polling for screen lock state:** Use DistributedNotificationCenter observers instead of CGSessionCopyCurrentDictionary
- **Fixed 1-second updates always:** Wastes battery when showing "2h 15m" - only need second precision when close
- **Setting colors via SwiftUI modifiers in MenuBarExtra label:** SwiftUI ignores foregroundColor in menu bar labels

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Menu bar colored text | SwiftUI foregroundColor modifier | NSAttributedString via MenuBarExtraAccess | SwiftUI modifiers ignored in menu bar |
| Adaptive timer updates | Multiple Timer instances | Custom TimelineSchedule | System manages lifecycle, battery optimized |
| Screen lock detection | Polling CGSession | DistributedNotificationCenter | Event-driven, zero overhead when idle |
| System colors | Hardcoded RGB values | NSColor.systemYellow/Orange/Red | Auto-adapts to dark/light mode |
| Icon state changes | Separate image assets | SF Symbols .symbolVariant() | Dynamic, no asset management |

**Key insight:** SwiftUI's MenuBarExtra is deliberately limited for consistency with system appearance. Colored text requires AppKit bridge - this is intentional, not a bug.

## Common Pitfalls

### Pitfall 1: TimelineView Schedule Not Updating When Event Changes
**What goes wrong:** Custom schedule is computed once; changing the target event doesn't recalculate entries
**Why it happens:** TimelineSchedule instances are struct values captured at creation time
**How to avoid:** Use .id(event.id) modifier on TimelineView to force recreation when event changes
**Warning signs:** Timer continues showing old countdown after event changes

### Pitfall 2: Menu Bar Text Color Ignored
**What goes wrong:** .foregroundColor() modifier has no effect on MenuBarLabel text
**Why it happens:** SwiftUI MenuBarExtra label is rendered as NSStatusItem, which ignores SwiftUI styling
**How to avoid:** Use MenuBarExtraAccess to access NSStatusItem.button.attributedTitle
**Warning signs:** Text always appears in default system color regardless of modifier

### Pitfall 3: Battery Drain from 1-Second Updates
**What goes wrong:** App uses significant battery even when showing "2h 15m"
**Why it happens:** Fixed 1-second interval updates when only minute precision is displayed
**How to avoid:** Implement adaptive schedule - 1s only when showing seconds, 60s otherwise
**Warning signs:** Activity Monitor shows high "Energy Impact" when app is idle

### Pitfall 4: Observer Memory Leak
**What goes wrong:** DistributedNotificationCenter observers not removed, causing retain cycles
**Why it happens:** addObserver with closure captures self strongly
**How to avoid:** Use [weak self] in closure, or store observer token and remove in deinit
**Warning signs:** SystemStateService instance never deallocated

### Pitfall 5: Color Transition Jarring
**What goes wrong:** Color changes abruptly when crossing threshold (59:59 to 60:00)
**Why it happens:** Immediate color switch without animation
**How to avoid:** Use withAnimation(.easeInOut(duration: 0.3)) when urgency level changes
**Warning signs:** Visual "flash" when timer crosses threshold

### Pitfall 6: Screen Lock Events Fire on Sleep
**What goes wrong:** App receives screenIsLocked before system sleep, but not always screenIsUnlocked on wake
**Why it happens:** macOS fires lock event before sleep; unlock might not fire if fast user switching
**How to avoid:** Also observe NSWorkspace.didWakeNotification and treat wake as potential unlock
**Warning signs:** Timer paused after waking from sleep

## Code Examples

Verified patterns from official sources:

### Hybrid Time Format
```swift
// Source: DateComponentsFormatter documentation
extension DateFormatters {
    static func formatHybridCountdown(until date: Date, from now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            return "Now"
        }

        if interval < 60 {
            return String(format: "%ds", Int(interval))
        }

        if interval < 300 { // 5 minutes - show seconds
            let minutes = Int(interval) / 60
            let seconds = Int(interval) % 60
            return String(format: "%dm %02ds", minutes, seconds)
        }

        if interval < 3600 { // 1 hour - minutes only
            let minutes = Int(interval) / 60
            return "\(minutes)m"
        }

        // Hours and minutes
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}
```

### SF Symbol Urgency Icon
```swift
// Source: SF Symbols documentation
struct UrgencyIcon: View {
    let level: UrgencyLevel

    var body: some View {
        Image(systemName: "calendar")
            .symbolVariant(level >= .soon ? .fill : .none)
            .foregroundStyle(level.swiftUIColor)
    }
}
```

### TimelineView with Adaptive Schedule Integration
```swift
// Source: TimelineView + custom schedule pattern
struct CountdownView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let event = appState.nextEvent {
            TimelineView(AdaptiveCountdownSchedule(eventDate: event.startDate)) { context in
                CountdownText(
                    event: event,
                    currentTime: context.date
                )
            }
            .id(event.id) // Force schedule recreation when event changes
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Timer.publish + onReceive | TimelineView | iOS 15 / macOS 12 | System-managed updates, battery efficient |
| NSStatusItem from scratch | MenuBarExtraAccess | macOS 13+ | Keep SwiftUI benefits, access AppKit features |
| Manual dark mode checks | NSColor.system* colors | macOS 10.14+ | Automatic appearance adaptation |
| Image assets for icon states | SF Symbols .symbolVariant() | iOS 15+ | Dynamic variant switching in code |

**Deprecated/outdated:**
- NSStatusItem.view property: Deprecated, use button property instead
- Manual timer invalidation patterns: TimelineView handles lifecycle automatically

## Open Questions

Things that couldn't be fully resolved:

1. **MenuBarExtraAccess + Color Animation**
   - What we know: attributedTitle can be set for colors
   - What's unclear: Whether withAnimation affects attributedTitle transitions, or if we need to animate at NSAttributedString level
   - Recommendation: Test with simple implementation first; if jarring, investigate NSViewAnimation or CoreAnimation on button layer

2. **TimelineView Coalescing Behavior**
   - What we know: SwiftUI may coalesce updates to conserve resources
   - What's unclear: How aggressive this is on macOS menu bar apps
   - Recommendation: Test with Activity Monitor; if updates skip, may need Timer fallback for final 60 seconds

3. **Icon Tinting in Menu Bar**
   - What we know: SF Symbols support tinting; template images are auto-tinted
   - What's unclear: Whether colored icon tint works in menu bar alongside colored text
   - Recommendation: Test icon coloring separately; may need to use attributedTitle with image attachment

## Sources

### Primary (HIGH confidence)
- Apple TimelineView documentation (concepts verified via multiple tutorials)
- DistributedNotificationCenter lock detection (verified via multiple implementations)
- NSStatusItem.button.attributedTitle (Apple documentation)
- SF Symbols symbolVariant() modifier (Apple documentation)

### Secondary (MEDIUM confidence)
- [MenuBarExtraAccess GitHub](https://github.com/orchetect/MenuBarExtraAccess) - Third-party but widely used
- [Swift with Majid - TimelineView](https://swiftwithmajid.com/2022/05/18/mastering-timelineview-in-swiftui/) - Trusted tutorial source
- [Ray Gesualdo - Lock Detection](https://www.raygesualdo.com/posts/building-a-macos-locked-status-notifier-in-swift/) - Working implementation

### Tertiary (LOW confidence)
- Adaptive TimelineSchedule pattern - Synthesized from documentation, needs validation
- Color animation on attributedTitle - Not confirmed, needs testing

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - MenuBarExtraAccess is third-party but necessary; alternatives verified
- Architecture: HIGH - Patterns follow established SwiftUI + AppKit bridge approaches
- Pitfalls: HIGH - Based on documented limitations and common issues
- Timer implementation: MEDIUM - Custom schedule pattern derived from docs, needs validation

**Research date:** 2026-01-24
**Valid until:** ~30 days (MenuBarExtraAccess may update; TimelineView API stable)
