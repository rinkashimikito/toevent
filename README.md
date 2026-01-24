# ToEvent

A macOS menu bar app that displays your next calendar event with a live countdown timer.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

## Features

- **Live Countdown** - Real-time timer in menu bar showing time until next event
- **Urgency Warnings** - Color-coded text (yellow 1h, orange 30m, red 15m)
- **Multiple Calendars** - Local (EventKit), Google Calendar, Outlook
- **Event List** - Dropdown showing upcoming events with details
- **One-Click Join** - Join Zoom, Meet, Teams, WebEx meetings directly
- **Smart Notifications** - Reminders with snooze options (3, 5, 10 min)
- **Focus Mode** - Filter events by context
- **Privacy Mode** - Hide event titles when sharing screen
- **Customizable** - Thresholds, display formats, keyboard shortcuts

## Installation

### Homebrew (Recommended)

```bash
brew tap rinkashimikito/toevent
brew install --cask toevent
```

After installation, clear the quarantine attribute (app is unsigned):

```bash
xattr -cr /Applications/ToEvent.app
```

### Direct Download

1. Download the latest DMG from [Releases](https://github.com/rinkashimikito/toevent/releases)
2. Drag ToEvent to Applications
3. Clear the quarantine attribute:

```bash
xattr -cr /Applications/ToEvent.app
```

### Why xattr -cr?

ToEvent is distributed without Apple Developer Program signing (it's free and open source). macOS Gatekeeper blocks unsigned apps by default. Running `xattr -cr` removes the quarantine flag so the app can launch.

Alternatively, you can right-click the app and select "Open" to bypass Gatekeeper on first launch.

## Requirements

- macOS 13.0 (Ventura) or later
- Calendar permission (for local calendars)
- For Google/Outlook: OAuth authentication

## Usage

1. Launch ToEvent - it appears in your menu bar
2. Grant calendar permission when prompted
3. Click the menu bar icon to see upcoming events
4. Configure settings via the gear icon

### External Calendars

To add Google Calendar or Outlook:

1. Open Settings (gear icon) > Calendars
2. Click "Add Account"
3. Authenticate with Google or Microsoft

### Keyboard Shortcut

Set a global shortcut in Settings > General to toggle the dropdown.

## Building from Source

```bash
git clone https://github.com/rinkashimikito/toevent.git
cd toevent
open ToEvent/ToEvent.xcodeproj
```

Build with Xcode 15+ targeting macOS 13.0.

### OAuth Credentials

For external calendar integration, you need your own OAuth credentials:

**Google Calendar:**

1. Create project at console.cloud.google.com
2. Enable Google Calendar API
3. Create OAuth 2.0 credentials (macOS app)
4. Add client ID to GoogleCalendarProvider.swift

**Microsoft Outlook:**

1. Register app at portal.azure.com
2. Add Calendar.Read permission
3. Create client secret
4. Add client ID to OutlookCalendarProvider.swift

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

GPL-3.0 - See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Sparkle](https://sparkle-project.org/) for auto-updates
- [Settings](https://github.com/sindresorhus/Settings) for preferences window
- [MenuBarExtraAccess](https://github.com/orchetect/MenuBarExtraAccess) for menu bar control
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) for global shortcuts
