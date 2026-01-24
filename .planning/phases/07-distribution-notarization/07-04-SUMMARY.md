---
phase: 07-distribution-notarization
plan: 04
subsystem: ci-cd
tags: [github-actions, release, signing, notarization, sparkle]

dependency-graph:
  requires: [07-01]
  provides: [automated-release, dmg-creation, appcast-generation]
  affects: []

tech-stack:
  added: [github-actions, create-dmg, notarytool]
  patterns: [conditional-signing, optional-notarization]

key-files:
  created: []
  modified:
    - .github/workflows/release.yml
    - ToEvent/ToEvent/Info.plist

decisions:
  - id: optional-signing
    choice: "Make signing conditional on secrets existence"
    reason: "Allow unsigned releases for developers without Apple Developer Program"
  - id: unsigned-build-flags
    choice: "Use CODE_SIGN_IDENTITY='-' for unsigned builds"
    reason: "Produces runnable app without certificate"
  - id: release-body-instructions
    choice: "Include xattr -cr instructions in release notes"
    reason: "Users need to know how to run unsigned apps"

metrics:
  duration: manual
  completed: 2026-01-26
---

# Phase 07 Plan 04: GitHub Actions Release Workflow Summary

Automated CI/CD pipeline that builds, optionally signs/notarizes, and releases ToEvent when tags are pushed.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create export-options.plist and release workflow | 9ad71c4 | scripts/export-options.plist, .github/workflows/release.yml |
| 2 | Add Sparkle EdDSA public key | 8b8c017 | ToEvent/ToEvent/Info.plist |
| 3 | Update workflow for optional signing | 21aadac | .github/workflows/release.yml |

## Implementation Details

### Workflow Behavior

**Without signing secrets (free tier):**
- Builds with `CODE_SIGN_IDENTITY="-"` (no signing)
- Creates DMG and ZIP
- Generates appcast without EdDSA signature
- Release notes include `xattr -cr` instructions

**With signing secrets (paid Developer ID):**
- Imports certificate from secrets
- Archives and exports with Developer ID signing
- Notarizes DMG with Apple
- Signs appcast with EdDSA

### Secrets (optional)

| Secret | Purpose |
|--------|---------|
| BUILD_CERTIFICATE_BASE64 | Developer ID Application cert |
| P12_PASSWORD | Certificate password |
| KEYCHAIN_PASSWORD | Temporary CI keychain |
| APPLE_ID | Notarization account |
| TEAM_ID | Developer team ID |
| NOTARIZATION_PASSWORD | App-specific password |
| SPARKLE_PRIVATE_KEY | EdDSA update signing |

### Trigger

Push tag matching `v*.*.*` (e.g., `git tag v0.9.0 && git push origin v0.9.0`)

## Verification Results

- [x] Workflow exists at .github/workflows/release.yml
- [x] Triggers on version tags
- [x] Builds unsigned when secrets missing
- [x] Builds signed when secrets present
- [x] Creates DMG and ZIP artifacts
- [x] Generates appcast.xml
- [x] Creates GitHub release with artifacts
- [x] Release notes explain unsigned installation

## Deviations from Plan

- Added optional signing mode (original plan assumed paid developer account)
- EdDSA key generated but private key not added to secrets (user choice)

## Commits

1. `9ad71c4` - feat(07-04): add GitHub Actions release workflow
2. `8b8c017` - feat(07-04): add Sparkle EdDSA public key to Info.plist
3. `21aadac` - feat(07-04): update release workflow for optional signing
