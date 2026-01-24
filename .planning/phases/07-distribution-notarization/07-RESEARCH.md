# Phase 7: Distribution + Notarization - Research

**Researched:** 2026-01-25
**Domain:** macOS code signing, notarization, Sparkle auto-updates, Homebrew cask distribution
**Confidence:** HIGH

## Summary

Distribution and notarization for macOS apps outside the Mac App Store requires a well-defined pipeline: code signing with Developer ID certificates, notarization via Apple's `notarytool`, stapling, DMG creation, and optionally Homebrew cask distribution. The current project already has most entitlements configured correctly for sandbox operation.

The standard approach uses GitHub Actions to automate the entire build-sign-notarize-release pipeline, triggered by semantic version tags. Sparkle 2 handles auto-updates for sandboxed apps through XPC services and requires specific entitlements. For open source projects not yet meeting Homebrew's notability threshold, a custom tap is the appropriate distribution method.

**Primary recommendation:** Use GitHub Actions with tag-triggered releases (v0.9.0 format), xcodebuild archive/export, notarytool for notarization, and Sparkle 2 via SPM for auto-updates. Create a custom Homebrew tap until notability threshold is reached.

## Standard Stack

The established libraries/tools for macOS distribution:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Sparkle | 2.8.1 | Auto-update framework | De facto standard for macOS apps, EdDSA signatures, sandboxing support |
| notarytool | Xcode 14+ | Notarization submission | Apple's official tool, replaced deprecated altool |
| create-dmg | latest | DMG creation | Widely used, simple, handles styling |
| GitHub Actions | N/A | CI/CD | Native macOS runner support, secrets management |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| xcrun stapler | Xcode 14+ | Ticket stapling | After successful notarization |
| security (CLI) | macOS | Keychain management | Certificate import in CI |
| generate_appcast | Sparkle 2.8+ | Appcast generation | After building release archives |
| generate_keys | Sparkle 2.8+ | EdDSA key generation | One-time setup for signing updates |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| create-dmg | hdiutil directly | More control but requires more configuration |
| Custom tap | homebrew-cask main repo | Main repo requires 30+ forks/watchers, 75+ stars |
| semantic-release | Manual tagging | Automation vs simplicity for small team |
| GitHub Pages appcast | External CDN | Free vs more control |

**Installation (Sparkle via SPM):**
```
In Xcode: File > Add Package Dependencies...
URL: https://github.com/sparkle-project/Sparkle
```

**Installation (create-dmg):**
```bash
brew install create-dmg
```

## Architecture Patterns

### Recommended CI/CD Structure
```
.github/
├── workflows/
│   └── release.yml          # Build, sign, notarize, release
├── ISSUE_TEMPLATE/
│   ├── bug_report.md
│   └── feature_request.md
└── PULL_REQUEST_TEMPLATE.md

scripts/
├── export-options.plist      # xcodebuild export configuration
└── sign-and-notarize.sh      # Local testing script (optional)
```

### Pattern 1: Tag-Triggered Release Workflow
**What:** GitHub Actions workflow triggered by semantic version tags
**When to use:** Every production release
**Example:**
```yaml
# Source: GitHub Actions documentation
name: Release
on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v5
      - name: Build and Sign
        # ... (detailed steps below)
```

### Pattern 2: ExportOptions.plist for Developer ID
**What:** Configuration file for xcodebuild -exportArchive
**When to use:** Required for Developer ID export
**Example:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$(DEVELOPMENT_TEAM)</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

### Pattern 3: Sparkle SwiftUI Integration
**What:** Observable pattern for "Check for Updates" menu item
**When to use:** For SwiftUI apps with Sparkle
**Example:**
```swift
// Source: sparkle-project.org/documentation/programmatic-setup/
import Sparkle

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}
```

### Anti-Patterns to Avoid
- **Using altool for notarization:** Deprecated, use notarytool instead
- **Skipping stapling:** Users on slow networks will experience launch delays
- **HTTP for appcast/downloads:** Always HTTPS for security
- **Hardcoding certificate names in workflow:** Use secrets/environment variables
- **Committing .p12 certificates:** Always base64 encode and store as secrets

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auto-updates | Custom update checker | Sparkle 2 | Delta updates, EdDSA signatures, UI, sandboxing |
| DMG creation | hdiutil scripts | create-dmg | Window positioning, background, symlinks |
| Notarization | Custom API calls | xcrun notarytool | Apple's official tool, handles edge cases |
| Certificate import | Manual keychain | security CLI pattern | Well-documented, CI-friendly |
| Version comparison | String comparison | Sparkle version parsing | Handles edge cases (1.0 vs 1.0.0) |

**Key insight:** Notarization and code signing have many edge cases (certificate types, entitlements, timestamps). Use Apple's tools and documented patterns.

## Common Pitfalls

### Pitfall 1: Missing Hardened Runtime
**What goes wrong:** Notarization fails with "not a hardened runtime" error
**Why it happens:** Hardened runtime not enabled in build settings
**How to avoid:** Verify ENABLE_HARDENED_RUNTIME = YES in project settings (already set in ToEvent)
**Warning signs:** Notarization rejection log mentions "hardened runtime"

### Pitfall 2: XPC Services Entitlement for Sparkle
**What goes wrong:** Sparkle can't install updates in sandboxed app
**Why it happens:** Missing temporary exception entitlements for XPC communication
**How to avoid:** Add Mach-lookup temporary exceptions to entitlements
**Warning signs:** Console logs show XPC connection failures during update

### Pitfall 3: Notarization Credential Storage
**What goes wrong:** Workflow hangs or fails on notarytool authentication
**Why it happens:** App-specific password not created, or wrong team ID
**How to avoid:** Create app-specific password at appleid.apple.com, store as secret
**Warning signs:** "Unable to authenticate" errors from notarytool

### Pitfall 4: First-Time Notarization Delays
**What goes wrong:** First notarization takes 12-24 hours
**Why it happens:** New developer accounts have slower initial review
**How to avoid:** Plan for delays on first submission, subsequent ones are minutes
**Warning signs:** "In Progress" status for extended periods

### Pitfall 5: Developer ID vs Development Certificate
**What goes wrong:** App works locally but Gatekeeper blocks on other machines
**Why it happens:** Wrong certificate type used (development instead of Developer ID)
**How to avoid:** Use "Developer ID Application" certificate for distribution
**Warning signs:** "Apple cannot check for malicious software" warning

### Pitfall 6: DEVELOPMENT_TEAM Empty in Project
**What goes wrong:** xcodebuild fails with signing errors
**Why it happens:** DEVELOPMENT_TEAM = "" in project settings (current state)
**How to avoid:** Will be set during CI via environment or must be configured
**Warning signs:** "No signing certificate" errors

## Code Examples

Verified patterns from official sources:

### GitHub Actions Certificate Import
```yaml
# Source: docs.github.com/en/actions/deployment/deploying-xcode-applications
- name: Install the Apple certificate
  env:
    BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
    P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

    echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH

    security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

    security import $CERTIFICATE_PATH -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
    security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security list-keychain -d user -s $KEYCHAIN_PATH
```

### xcodebuild Archive and Export
```bash
# Archive
xcodebuild archive \
  -project ToEvent/ToEvent.xcodeproj \
  -scheme ToEvent \
  -configuration Release \
  -archivePath build/ToEvent.xcarchive \
  -destination "generic/platform=macOS"

# Export for Developer ID
xcodebuild -exportArchive \
  -archivePath build/ToEvent.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist scripts/export-options.plist
```

### Notarization with notarytool
```bash
# Store credentials (one-time setup or in CI)
xcrun notarytool store-credentials "NotaryProfile" \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_SPECIFIC_PASSWORD"

# Submit for notarization
xcrun notarytool submit "ToEvent.dmg" \
  --keychain-profile "NotaryProfile" \
  --wait

# Staple the ticket
xcrun stapler staple "ToEvent.dmg"
```

### Sparkle Entitlements for Sandboxed App
```xml
<!-- Add to ToEvent.entitlements -->
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>
</array>
```

### Sparkle Info.plist Keys
```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/Immedio/toevent/master/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_BASE64_PUBLIC_KEY</string>
<key>SUEnableInstallerLauncherService</key>
<true/>
```

### Main App with Sparkle Updater
```swift
// Source: sparkle-project.org/documentation/programmatic-setup/
import SwiftUI
import Sparkle

@main
struct ToEventApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        // existing MenuBarExtra...

        Settings {
            // existing settings...
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
```

### Homebrew Cask File (Custom Tap)
```ruby
# homebrew-toevent/Casks/toevent.rb
cask "toevent" do
  version "0.9.0"
  sha256 "COMPUTED_SHA256_HASH"

  url "https://github.com/Immedio/toevent/releases/download/v#{version}/ToEvent-#{version}.dmg"
  name "ToEvent"
  desc "Menu bar app showing next calendar event with countdown"
  homepage "https://github.com/Immedio/toevent"

  depends_on macos: ">= :ventura"

  app "ToEvent.app"

  zap trash: [
    "~/Library/Preferences/com.immedio.ToEvent.plist",
    "~/Library/Application Support/ToEvent",
  ]
end
```

### Appcast.xml Format
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>ToEvent Updates</title>
    <language>en</language>
    <item>
      <title>Version 0.9.0</title>
      <sparkle:version>1</sparkle:version>
      <sparkle:shortVersionString>0.9.0</sparkle:shortVersionString>
      <sparkle:releaseNotesLink>https://github.com/Immedio/toevent/releases/tag/v0.9.0</sparkle:releaseNotesLink>
      <pubDate>Sat, 25 Jan 2026 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/Immedio/toevent/releases/download/v0.9.0/ToEvent-0.9.0.zip"
        sparkle:edSignature="SIGNATURE_HERE"
        length="FILE_SIZE"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
```

### Version Tracking for What's New
```swift
// Simple pattern for showing changelog on version update
struct WhatsNewCheck {
    private static let lastVersionKey = "lastSeenVersion"

    static func shouldShowWhatsNew() -> Bool {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)
        return lastVersion != currentVersion
    }

    static func markAsSeen() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| altool | notarytool | Xcode 14 (2022) | Must migrate, altool deprecated |
| Sparkle 1 | Sparkle 2 | 2020+ | Sandboxing support, EdDSA signatures |
| DSA signatures | EdDSA signatures | Sparkle 2 | More secure, required for new apps |
| CocoaPods Sparkle | SPM Sparkle | 2023+ | CocoaPods deprecated for Sparkle |
| Unsigned casks | Signed casks only | Homebrew 5.0 (2025) | Unsigned deprecated, disabled Sept 2026 |

**Deprecated/outdated:**
- altool: Use notarytool instead
- Sparkle 1: Use Sparkle 2 for sandboxing
- CocoaPods for Sparkle: Use Swift Package Manager
- DSA signatures: Use EdDSA for Sparkle

## Open Questions

Things that couldn't be fully resolved:

1. **Apple Developer Account Setup**
   - What we know: Developer ID certificate requires paid Apple Developer Program ($99/year)
   - What's unclear: Whether account is already set up, Team ID
   - Recommendation: Verify account status before starting implementation

2. **GitHub Repository Permissions**
   - What we know: Need to add secrets for certificates and passwords
   - What's unclear: Who has admin access to repository settings
   - Recommendation: Confirm repository admin access before workflow setup

3. **Appcast Hosting Location**
   - What we know: Can use GitHub raw content or GitHub Pages
   - What's unclear: Preferred URL structure for the project
   - Recommendation: Use raw.githubusercontent.com for simplicity, can migrate later

4. **Initial Version Number**
   - What we know: User wants beta version (0.9.0 or 0.1.0)
   - What's unclear: Preference between options
   - Recommendation: 0.9.0 signals "nearly ready," 0.1.0 signals "early development"

## GitHub Secrets Required

For the release workflow to function:

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| BUILD_CERTIFICATE_BASE64 | Base64-encoded Developer ID Application .p12 | Export from Keychain Access, `base64 -i cert.p12 \| pbcopy` |
| P12_PASSWORD | Password used when exporting certificate | Set during Keychain export |
| KEYCHAIN_PASSWORD | Temporary keychain password | Any random string |
| APPLE_ID | Apple Developer email | Your Apple ID |
| TEAM_ID | 10-character Team ID | developer.apple.com/account > Membership |
| NOTARIZATION_PASSWORD | App-specific password | appleid.apple.com > App-Specific Passwords |

## Entitlements Analysis

Current entitlements in ToEvent.entitlements are appropriate:

| Entitlement | Current | Purpose | Status |
|-------------|---------|---------|--------|
| com.apple.security.app-sandbox | true | Enable sandbox | Required |
| com.apple.security.personal-information.calendars | true | Calendar access | Required |
| com.apple.security.automation.apple-events | true | Apple Events | For meeting links |
| com.apple.security.network.client | true | Network access | For OAuth, Sparkle downloads |

**Additions needed for Sparkle:**
- com.apple.security.temporary-exception.mach-lookup.global-name (array with XPC service names)

## Sources

### Primary (HIGH confidence)
- [GitHub Actions Apple Certificate Documentation](https://docs.github.com/en/actions/deployment/deploying-xcode-applications/installing-an-apple-certificate-on-macos-runners-for-xcode-development) - Complete workflow example
- [Sparkle Documentation](https://sparkle-project.org/documentation/) - SwiftUI setup, sandboxing
- [Sparkle Sandboxing Guide](https://sparkle-project.org/documentation/sandboxing/) - XPC services, entitlements
- [Sparkle Programmatic Setup](https://sparkle-project.org/documentation/programmatic-setup/) - SwiftUI code examples
- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook) - Cask file format
- [Homebrew Acceptable Casks](https://docs.brew.sh/Acceptable-Casks) - Notability requirements
- [create-dmg (sindresorhus)](https://github.com/sindresorhus/create-dmg) - DMG creation

### Secondary (MEDIUM confidence)
- [Federico Terzi Code Signing Guide](https://federicoterzi.com/blog/automatic-code-signing-and-notarization-for-macos-apps-using-github-actions/) - Workflow patterns
- [defn.io Mac Distribution](https://defn.io/2023/09/22/distributing-mac-apps-with-github-actions/) - End-to-end workflow
- [Apple Developer ID Overview](https://developer.apple.com/developer-id/) - Certificate requirements

### Tertiary (LOW confidence)
- WebSearch results for semantic-release patterns - community practices
- OnboardingKit references - potential library for what's new screen

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Well-documented Apple and Sparkle tooling
- Architecture: HIGH - GitHub Actions patterns are well-established
- Pitfalls: HIGH - Common issues documented across multiple sources
- Homebrew cask: MEDIUM - Custom tap approach clear, main repo requirements verified

**Research date:** 2026-01-25
**Valid until:** 60 days (stable domain, infrequent API changes)
