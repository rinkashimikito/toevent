---
phase: 05-external-calendar-apis
plan: 06
subsystem: ui
tags: [settings, account-management, oauth-ui, calendar-settings]

requires:
  - phase: 05-05
    provides: CalendarProviderManager for multi-source aggregation
  - phase: 05-02
    provides: AuthService for OAuth flow

provides:
  - AddAccountSheet for Google/Outlook OAuth provider selection
  - CalendarSettingsView with account management and source indicators
  - Re-authentication UI for expired tokens
  - Account removal capability

affects: [user-onboarding, external-calendar-flow]

tech-stack:
  added: []
  patterns: [sheet-with-callback, provider-manager-integration, settings-container]

key-files:
  created:
    - ToEvent/ToEvent/Views/Settings/AddAccountSheet.swift
  modified:
    - ToEvent/ToEvent/Views/Settings/CalendarSettingsView.swift

key-decisions:
  - "AddAccountSheet uses callback pattern for account creation notification"
  - "Provider symbol icons indicate calendar source in list"
  - "Re-auth warning section appears at top when accounts expire"
  - "Connected accounts section with remove button"
  - "Calendar fetching delegated to CalendarProviderManager"

patterns-established:
  - "Sheet with callback pattern for modal actions returning data"
  - "Provider icon display via CalendarProviderType.symbolName"
  - "Settings UI structure with SettingsContainer/SettingsSection"

duration: 3min
completed: 2026-01-24
---

# Phase 5 Plan 6: Account Management UI Summary

**AddAccountSheet enables Google/Outlook OAuth, CalendarSettingsView shows source icons and account management**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-24T22:00:00Z
- **Completed:** 2026-01-24T22:03:00Z
- **Tasks:** 3 (2 auto + 1 checkpoint)
- **Files modified:** 2

## Accomplishments
- AddAccountSheet provides Google and Outlook OAuth provider selection
- CalendarSettingsView displays source icons per calendar (local/Google/Outlook)
- Connected accounts section shows all linked accounts with remove option
- Re-authentication warning appears when account tokens expire
- Calendar list fetches from CalendarProviderManager for multi-source support

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AddAccountSheet** - `0c6ee74` (feat)
2. **Task 2: Extend CalendarSettingsView for account management** - `c418d92` (feat)
3. **Task 3: Human verification checkpoint** - No commit (verification only)

Additional fixes during execution:
- `fe722d6` - fix: remove unnecessary keychain-access-groups entitlement
- `26fe681` - fix: add missing Phase 5 files to Xcode project
- `fe6788c` - fix: use pattern matching for error comparison
- `ac36ba1` - fix: remove incorrect Settings.Section cast
- `03aead6` - fix: restructure CalendarSettingsView for Settings package compatibility

## Files Created/Modified
- `ToEvent/ToEvent/Views/Settings/AddAccountSheet.swift` - Sheet for selecting Google or Outlook and triggering OAuth
- `ToEvent/ToEvent/Views/Settings/CalendarSettingsView.swift` - Extended with Add Account button, source icons, connected accounts, re-auth warnings

## Decisions Made
- AddAccountSheet uses callback pattern (onAccountAdded closure) to notify parent of new account
- Provider type symbol names display source icons (calendar, g.circle, m.circle)
- Re-authentication warning section positioned at top of settings for visibility
- Connected accounts section appears only when accounts exist
- Calendar loading delegated to CalendarProviderManager.fetchAllCalendars()
- SettingsContainer/SettingsSection used for consistent settings UI structure

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Xcode project missing Phase 5 files**
- **Found during:** Task 1
- **Issue:** New files from Phase 5 not added to Xcode project, causing build failures
- **Fix:** Added all Phase 5 service files to the Xcode project
- **Files modified:** ToEvent.xcodeproj
- **Committed in:** `26fe681`

**2. [Rule 1 - Bug] Pattern matching for error comparison**
- **Found during:** Task 2
- **Issue:** Direct error comparison not compiling correctly
- **Fix:** Used pattern matching for error type comparison
- **Committed in:** `fe6788c`

**3. [Rule 1 - Bug] Settings.Section incompatibility**
- **Found during:** Task 2
- **Issue:** CalendarSettingsView structure incompatible with Settings package
- **Fix:** Restructured to use SettingsContainer and SettingsSection properly
- **Committed in:** `ac36ba1`, `03aead6`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking)
**Impact on plan:** All fixes necessary for build and runtime correctness. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviations.

## User Setup Required

None - UI components work with existing AuthService and CalendarProviderManager infrastructure. OAuth credentials configured in earlier phases.

## Next Phase Readiness
- Phase 5 (External Calendar APIs) complete
- Users can add Google and Outlook accounts from Settings
- Calendars display source icons showing where events come from
- Token expiry triggers re-authentication prompts
- Multi-provider architecture fully integrated with UI

---
*Phase: 05-external-calendar-apis*
*Completed: 2026-01-24*
