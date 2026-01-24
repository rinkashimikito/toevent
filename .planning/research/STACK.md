# Stack Research

**Domain:** macOS menu bar apps with calendar integration
**Researched:** 2026-01-24
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.2+ | Primary language | Modern concurrency (async/await), data-race safety by default, approachable concurrency model with MainActor isolation. Swift 6.2's progressive disclosure means simple code stays simple. |
| SwiftUI | Latest (macOS 13+) | UI framework | Declarative UI with MenuBarExtra scene for native menu bar integration. Reduces boilerplate compared to AppKit while providing full menu bar app support. |
| EventKit | Framework (macOS 10.8+) | Calendar data access | Apple's native calendar framework. Direct access to local calendar data with write-only permissions (macOS Sonoma+) for privacy-first design. Single EKEventStore instance pattern. |
| MenuBarExtra | Scene (macOS 13+) | Menu bar integration | Native SwiftUI scene type introduced in macOS 13 Ventura. Eliminates need for AppKit bridging. Simpler than NSStatusItem for standard menu bar apps. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| UserNotifications | Framework (macOS 10.14+) | Local notifications | Popup reminders before events. UNUserNotificationCenter handles authorization and scheduling. |
| async/await | Swift 6.2+ | Asynchronous operations | API calls to Google/Outlook Calendar. One-off operations with clean error handling. Replaces completion handlers. |
| Combine | Framework (macOS 10.15+) | Reactive streams | Real-time countdown updates, continuous UI state changes. Ideal for timer-based updates and data streams over time. |
| Swift Testing | Framework (Swift 6.0+) | Unit testing | Modern testing with @Test/@Suite macros and #expect assertions. Runs alongside XCTest for incremental migration. |

### External API Integration

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GoogleSignIn | Latest via SPM | Google OAuth | Google Calendar API authentication. Required for Google account access. |
| GoogleAPIClient | Latest via SPM | Google Calendar API | Read/create events in Google Calendar. Use with Swift concurrency wrappers. |
| Microsoft Graph SDK | Latest via SPM | Outlook Calendar API | Read/create events in Outlook/Microsoft 365. RESTful API with Swift support. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode | IDE and build system | Latest stable version. Required for macOS development. |
| Swift Package Manager | Dependency management | Built into Xcode 11+. Preferred over CocoaPods for macOS-only apps. |
| Instruments | Performance profiling | Monitor CPU usage, timers, and battery impact. Critical for menu bar apps. |
| XCTest | Legacy unit testing | Runs side-by-side with Swift Testing. Use for existing tests. |

## Installation

```bash
# No package installation needed for core stack (all frameworks built-in)
# External APIs added via Xcode: File → Add Package Dependencies

# Google Calendar API
# URL: https://github.com/google/GoogleSignIn-iOS
# URL: https://github.com/google/google-api-objectivec-client-for-rest

# Microsoft Graph SDK
# URL: https://github.com/microsoftgraph/msgraph-sdk-objc
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Swift 6.2 | Swift 5.x | Never. Swift 6.2 has better concurrency, safer defaults, and is standard for 2026. |
| SwiftUI MenuBarExtra | AppKit NSStatusItem | Complex custom menu bar UI beyond MenuBarExtra capabilities. MenuBarExtra sufficient for ToEvent. |
| EventKit | Google/Outlook APIs only | When users don't use local calendars. EventKit provides best performance and privacy for macOS users. |
| async/await | Combine for API calls | Never for one-off operations. async/await is cleaner and standard for modern Swift. |
| Combine | async/await for timers | Never for real-time streams. Combine designed for continuous event handling. |
| Swift Testing | XCTest only | Never for new tests. Swift Testing has better ergonomics and cross-platform support. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Electron | Battery drain, 200MB+ memory footprint, not native UI, violates "native macOS" constraint | SwiftUI with MenuBarExtra |
| React Native | No official macOS menu bar support, requires third-party bridges, non-native feel | SwiftUI |
| CocoaPods | Legacy dependency manager, adds complexity for macOS-only apps, slower than SPM | Swift Package Manager |
| Swift 5.x concurrency backports | Incomplete data-race safety, outdated patterns, no MainActor defaults | Swift 6.2 native concurrency |
| Third-party calendar wrappers | Adds dependency layer over EventKit, no meaningful abstraction, potential privacy issues | EventKit directly |
| Polling for updates | Battery drain, unnecessary CPU usage, violates efficiency requirement | Timer.publish() with reasonable intervals (1 min for countdown) |
| NSStatusBarButton manual setup | Boilerplate-heavy, requires AppKit knowledge, MenuBarExtra solves this | MenuBarExtra scene |

## Stack Patterns by Variant

**If targeting macOS 12 or earlier:**
- Cannot use MenuBarExtra (requires macOS 13+)
- Must use AppKit NSStatusItem directly
- Recommendation: Set minimum deployment target to macOS 13 (all supported Macs as of 2026 run 13+)

**If Google/Outlook API calls fail:**
- Fallback to EventKit-only mode
- Many users sync calendars to local macOS Calendar.app
- EventKit can read Google/Outlook events synced via system preferences

**If battery efficiency is critical:**
- Use Timer.publish() with longer intervals (60s minimum for countdown)
- Implement App Nap support (automatic in SwiftUI)
- Avoid polling APIs - use EventKit change notifications
- Profile with Instruments Energy Log

**If open source distribution:**
- No sandboxing required (only for App Store)
- Still request calendar permissions via Info.plist keys
- Document required entitlements for users building from source

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Swift 6.2 | macOS 13+ | Approachable concurrency requires recent toolchain. Xcode 16+. |
| MenuBarExtra | macOS 13+ | Ventura or later required. 95%+ of active Macs supported. |
| EventKit write-only access | macOS 14+ (Sonoma) | Fallback to full access on macOS 13. Use NSCalendarsWriteOnlyAccessUsageDescription. |
| SwiftUI @Observable | macOS 14+ | For state management. Use @StateObject on macOS 13. |
| Swift Testing | Swift 6.0+ | Xcode 16+. Runs alongside XCTest. |

## Privacy and Entitlements

**Required Info.plist Keys:**

```xml
<!-- Local calendar access -->
<key>NSCalendarsUsageDescription</key>
<string>ToEvent displays your upcoming calendar events in the menu bar</string>

<!-- Write-only access (macOS 14+, optional) -->
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>ToEvent needs to add quick events to your calendar</string>

<!-- Notifications -->
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>

<!-- Menu bar only app (no dock icon) -->
<key>LSUIElement</key>
<true/>
```

**App Sandbox (if distributing via App Store):**
- com.apple.security.app-sandbox = YES
- com.apple.security.personal-information.calendars = YES
- Calendar access requires explicit entitlement even with Info.plist keys

## Deployment Targets

**Recommended Minimum:**
- macOS 13.0 (Ventura) - enables MenuBarExtra, covers 95%+ of active Macs in 2026
- Swift 6.2 (Xcode 16+)

**Rationale:**
- macOS 13 released September 2022 (4 years old by 2026)
- macOS 14/15/16 (Sonoma/Sequoia/Tahoe) add features but not required
- Targeting macOS 12 requires NSStatusItem AppKit approach (significant complexity increase)

## Sources

- [MenuBarExtra | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/menubarextra) - HIGH confidence
- [EventKit | Apple Developer Documentation](https://developer.apple.com/documentation/eventkit) - HIGH confidence
- [Swift 6.2 Released | Swift.org](https://www.swift.org/blog/swift-6.2-released/) - HIGH confidence
- [Approachable Concurrency in Swift 6.2](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) - HIGH confidence
- [Mastering SwiftUI: Combine vs Async/Await in 2026](https://medium.com/@viralswift/mastering-swiftui-combine-vs-async-await-when-to-use-what-in-2026-c458d64eaf35) - MEDIUM confidence
- [Creating Menu Bar Apps in SwiftUI for macOS Ventura](https://sarunw.com/posts/swiftui-menu-bar-app/) - HIGH confidence
- [NSStatusItem Best Practices](https://www.peterarsenault.industries/posts/macos-status-bar-apps/part01/) - HIGH confidence
- [Google Calendar API Overview](https://developers.google.com/calendar/api/guides/overview) - HIGH confidence
- [Microsoft Graph Calendar API](https://learn.microsoft.com/en-us/graph/outlook-calendar-concept-overview) - HIGH confidence
- [Energy Efficiency Guide for Mac Apps](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/index.html) - HIGH confidence
- [Swift Testing Documentation](https://developer.apple.com/xcode/swift-testing) - HIGH confidence
- [macOS App Sandbox](https://developer.apple.com/documentation/security/app-sandbox) - HIGH confidence

---
*Stack research for: ToEvent macOS menu bar calendar app*
*Researched: 2026-01-24*
