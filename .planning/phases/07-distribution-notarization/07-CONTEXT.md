# Phase 7: Distribution + Notarization - Context

**Gathered:** 2026-01-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Code signing, notarization, and public release. Packaging ToEvent for macOS installation via Homebrew cask and direct download. Includes auto-update mechanism and open source community setup.

</domain>

<decisions>
## Implementation Decisions

### Distribution channels
- Both Homebrew cask and GitHub releases
- No Mac App Store for v1 (different sandboxing, review delays)
- DMG for direct download, zip for Homebrew
- Maintain macOS 13 (Ventura) minimum — matches current deployment target

### Release automation
- Semantic versioning (major.minor.patch)
- First release as beta (0.9.0 or 0.1.0) — signals early stage
- Build/release process and trigger mechanism: Claude's discretion

### Installer experience
- Show welcome/changelog on first launch of new version
- Sparkle framework for auto-updates
- DMG styling: Claude's discretion
- Update check frequency: Claude's discretion

### Open source setup
- GPL-3.0 license (copyleft)
- Full documentation site (GitHub Pages or similar)
- Standard community files: CODE_OF_CONDUCT, CONTRIBUTING, SECURITY, issue templates
- OAuth credential handling: Claude's discretion

### Claude's Discretion
- Build automation choice (GitHub Actions vs manual)
- Release trigger mechanism (git tag vs manual dispatch)
- DMG background/styling
- Sparkle update check frequency
- OAuth credential strategy for contributors

</decisions>

<specifics>
## Specific Ideas

- User wants beta version number (0.9.0 or 0.1.0) to signal this is early/preview release
- Full docs site rather than just README — indicates intent for community growth

</specifics>

<deferred>
## Deferred Ideas

- Mac App Store distribution — future milestone, not v1

</deferred>

---

*Phase: 07-distribution-notarization*
*Context gathered: 2026-01-25*
