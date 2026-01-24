---
phase: 07-distribution-notarization
plan: 06
subsystem: distribution
tags: [homebrew, cask, tap, macos]

requires:
  - phase: 07-04
    provides: GitHub release workflow and DMG artifacts
provides:
  - Homebrew tap repository at rinkashimikito/homebrew-toevent
  - Cask formula with postflight for unsigned app
  - Installation via brew tap + brew install
affects: []

tech-stack:
  added: []
  patterns:
    - Homebrew cask distribution
    - Postflight xattr for unsigned apps

key-files:
  created:
    - (external) github.com/rinkashimikito/homebrew-toevent/Casks/toevent.rb
  modified: []

key-decisions:
  - "sha256 :no_check for initial release (update after first actual release)"
  - "postflight xattr -cr for unsigned app Gatekeeper bypass"
  - "Caveats block explains manual xattr workaround"

patterns-established:
  - "Postflight stanza: Clear quarantine attributes for unsigned distribution"

duration: 3min
completed: 2026-01-26
---

# Phase 7 Plan 6: Homebrew Tap Summary

**Homebrew tap with cask formula including postflight xattr for unsigned macOS app distribution**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-26T20:57:01Z
- **Completed:** 2026-01-26T21:00:00Z
- **Tasks:** 2/3 (Task 3 is verification checkpoint)
- **Files modified:** 0 (all work in external tap repository)

## Accomplishments

- Created Homebrew tap repository at github.com/rinkashimikito/homebrew-toevent
- Implemented cask formula with postflight stanza to clear quarantine attributes
- Added caveats explaining unsigned app distribution and manual workaround
- Configured for macOS Ventura and later

## Task Commits

Work completed in external tap repository (rinkashimikito/homebrew-toevent):

1. **Task 1: Create tap repository** - User action (checkpoint completed)
2. **Task 2: Create cask formula** - `307ce3e` in tap repo

## Files Created/Modified

In tap repository (github.com/rinkashimikito/homebrew-toevent):
- `Casks/toevent.rb` - Homebrew cask formula with postflight and caveats
- `README.md` - Installation instructions and unsigned app notes

## Decisions Made

- **sha256 :no_check**: Used temporarily since no release exists yet. Must update after first actual release with real hash.
- **Postflight xattr**: Essential for unsigned app - clears quarantine so Gatekeeper allows execution
- **Caveats block**: Explains the unsigned situation and provides manual workaround for users who encounter issues

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- HTTPS push failed due to missing credentials - switched to SSH URL

## User Setup Required

After first release (v0.9.0):
1. Download DMG from GitHub release
2. Calculate SHA256: `shasum -a 256 ToEvent-0.9.0.dmg`
3. Update sha256 in Casks/toevent.rb (replace `:no_check` with actual hash)
4. Push update to tap repo

## Next Phase Readiness

- Distribution infrastructure complete
- Installation path: `brew tap rinkashimikito/toevent && brew install --cask toevent`
- Awaiting verification checkpoint (Task 3)

---
*Phase: 07-distribution-notarization*
*Completed: 2026-01-26*
