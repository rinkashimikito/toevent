import SwiftUI
import LaunchAtLogin
import KeyboardShortcuts

struct GeneralSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var updaterController: UpdaterController

    private let lookaheadOptions: [(String, TimeInterval)] = [
        ("1 hour", 3600),
        ("6 hours", 21600),
        ("12 hours", 43200),
        ("24 hours", 86400),
        ("48 hours", 172800),
        ("7 days", 604800)
    ]

    var body: some View {
        Form {
            Section("Startup") {
                LaunchAtLogin.Toggle("Launch ToEvent at login")
            }

            Section("Keyboard Shortcut") {
                KeyboardShortcuts.Recorder("Toggle dropdown:", name: .toggleDropdown)
            }

            Section("Events") {
                Picker("Show events in the next:", selection: $appState.lookahead) {
                    ForEach(lookaheadOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .onChange(of: appState.lookahead) { _ in
                    appState.refreshEvents()
                }
            }

            Section("Updates") {
                Button("Check for Updates...") {
                    updaterController.checkForUpdates()
                }
                .disabled(!updaterController.canCheckForUpdates)
            }
        }
        .formStyle(.grouped)
        .padding()
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
