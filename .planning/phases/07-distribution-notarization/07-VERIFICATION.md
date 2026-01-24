---
phase: 07-distribution-notarization
verified: 2026-01-26T21:15:00Z
status: passed
score: 6/6 must-haves verified
---

# Phase 7: Distribution + Notarization Verification Report

**Phase Goal:** Code signing, notarization, and public release
**Verified:** 2026-01-26T21:15:00Z
**Status:** passed
**Re-verification:** No - initial verification

**Context:** App distributed UNSIGNED (user chose not to pay for Apple Developer Program). Code signing and notarization are OPTIONAL - workflow supports both modes.

## Goal Achievement

### Observable Truths (Adjusted for Unsigned Distribution)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App CAN BE code-signed (workflow supports it) | VERIFIED | `.github/workflows/release.yml` lines 29-47, 70-83 conditionally install cert and archive with signing |
| 2 | App CAN BE notarized (workflow supports it) | VERIFIED | `.github/workflows/release.yml` lines 104-119 notarize step runs when signing secrets exist |
| 3 | App has proper sandbox entitlements | VERIFIED | `ToEvent/ToEvent/ToEvent.entitlements` has sandbox=true, calendars, apple-events, network.client, XPC mach-lookup |
| 4 | Homebrew cask is available | VERIFIED | `/tmp/homebrew-toevent/Casks/toevent.rb` (35 lines) with postflight xattr -cr |
| 5 | GitHub releases have workflow for compiled binaries | VERIFIED | `.github/workflows/release.yml` creates DMG, ZIP, appcast.xml, uploads to release |
| 6 | Unsigned app handling documented | VERIFIED | README.md lines 29-49, release.yml lines 179-188, cask caveats all explain xattr -cr |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ToEvent/ToEvent/ToEvent.entitlements` | Sandbox entitlements | VERIFIED | 19 lines, sandbox + calendar + apple-events + network + XPC |
| `.github/workflows/release.yml` | Release automation | VERIFIED | 189 lines, conditional signing, DMG creation, notarization, appcast |
| `ToEvent/ToEvent/Services/UpdaterController.swift` | Sparkle wrapper | VERIFIED | 23 lines, SPUStandardUpdaterController, Combine publisher |
| `ToEvent/ToEvent/Info.plist` | Sparkle config | VERIFIED | SUFeedURL, SUEnableInstallerLauncherService, SUPublicEDKey |
| `README.md` | Project documentation | VERIFIED | 118 lines, installation, xattr -cr instructions, build guide |
| `LICENSE` | GPL-3.0 license | VERIFIED | 21 lines, proper GPL-3.0 notice |
| `CONTRIBUTING.md` | Contribution guide | VERIFIED | 58 lines, build setup, PR process |
| `CODE_OF_CONDUCT.md` | Community standards | VERIFIED | 1260 bytes, Contributor Covenant |
| `SECURITY.md` | Security policy | VERIFIED | 742 bytes, disclosure process |
| `CHANGELOG.md` | Release notes | VERIFIED | 31 lines, 0.9.0 with all features |
| `.github/ISSUE_TEMPLATE/*.md` | Issue templates | VERIFIED | bug_report.md, feature_request.md |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template | VERIFIED | 331 bytes |
| `ToEvent/ToEvent/Utilities/WhatsNewCheck.swift` | Version tracking | VERIFIED | 25 lines, UserDefaults version comparison |
| `ToEvent/ToEvent/Views/WhatsNewView.swift` | What's New UI | VERIFIED | 67 lines, changelog display with dismiss |
| `/tmp/homebrew-toevent/Casks/toevent.rb` | Homebrew cask | VERIFIED | 35 lines, postflight xattr, caveats |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| ToEventApp.swift | UpdaterController | @StateObject + .environmentObject | WIRED | Line 61 creates, line 123 injects |
| GeneralSettingsView | UpdaterController | @EnvironmentObject + button action | WIRED | Line 7 receives, line 41 calls checkForUpdates() |
| ToEventApp.swift | WhatsNewView | @State + .sheet | WIRED | Lines 63, 89-95 check version, show sheet |
| Info.plist | Sparkle | SUFeedURL, SUPublicEDKey | WIRED | Lines 24-29 configure update feed and key |
| release.yml | GitHub Release | softprops/action-gh-release | WIRED | Lines 171-189 upload artifacts |
| Cask formula | GitHub Release | DMG download URL | WIRED | Line 5 points to releases/download |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | - | - | - | - |

No TODO, FIXME, or placeholder patterns found in key distribution files.

### Human Verification Required

#### 1. GitHub Actions Workflow Execution
**Test:** Push a version tag (e.g., `v0.9.0`) to trigger release workflow
**Expected:** Workflow creates DMG, ZIP, appcast.xml and attaches to GitHub release
**Why human:** Requires actual tag push and workflow execution

#### 2. Homebrew Installation
**Test:** Run `brew tap Immedio/toevent && brew install --cask toevent`
**Expected:** ToEvent installs, postflight clears quarantine, app launches
**Why human:** Requires first release with DMG artifact

#### 3. Sparkle Update Check
**Test:** Click "Check for Updates..." in Settings > General
**Expected:** Sparkle checks appcast.xml (may show "no updates" if latest)
**Why human:** Requires running app and appcast.xml on release URL

#### 4. What's New Screen
**Test:** Upgrade from one version to another (or modify lastSeenVersion in UserDefaults)
**Expected:** What's New sheet appears on first launch after upgrade
**Why human:** Requires simulating version upgrade

### Gaps Summary

No gaps found. All artifacts verified at existence, substantive, and wiring levels.

### Optional Signing Infrastructure (Verified but Not Active)

The workflow supports full signing/notarization when these secrets are configured:
- `BUILD_CERTIFICATE_BASE64` - Developer ID Application certificate
- `P12_PASSWORD` - Certificate password
- `KEYCHAIN_PASSWORD` - CI keychain password
- `APPLE_ID` - Notarization account
- `TEAM_ID` - Developer team ID
- `NOTARIZATION_PASSWORD` - App-specific password
- `SPARKLE_PRIVATE_KEY` - EdDSA update signing key

Without these secrets, the workflow builds unsigned and documents the xattr workaround in release notes.

---

_Verified: 2026-01-26T21:15:00Z_
_Verifier: Claude (gsd-verifier)_
