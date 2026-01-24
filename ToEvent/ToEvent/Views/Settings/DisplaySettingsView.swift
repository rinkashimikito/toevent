import SwiftUI

struct DisplaySettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Time Display") {
                Picker("Format:", selection: $appState.timeDisplayFormat) {
                    ForEach(TimeDisplayFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }

                Toggle("Use natural language (\"soon\" instead of \"in 5m\")", isOn: $appState.useNaturalLanguage)
                    .disabled(appState.timeDisplayFormat == .absolute)
            }

            Section("Menu Bar") {
                Toggle("Show calendar icon", isOn: $appState.showMenuBarIcon)

                HStack {
                    Text("Title length:")
                    Slider(
                        value: Binding(
                            get: { Double(appState.menuBarTitleMaxLength) },
                            set: { appState.menuBarTitleMaxLength = Int($0) }
                        ),
                        in: 0...50,
                        step: 1
                    )
                    Text(appState.menuBarTitleMaxLength == 0 ? "Full" : "\(appState.menuBarTitleMaxLength)")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Event List") {
                Toggle("Hide all-day events", isOn: $appState.hideAllDayEvents)
            }

            Section("Privacy") {
                Toggle("Hide event titles", isOn: $appState.privacyMode)
                Text("Shows \"Event\" instead of actual event title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

extension DisplaySettingsView {
    static let pane: SettingsPane = SettingsPane(
        identifier: SettingsPaneIdentifier("display"),
        title: "Display",
        toolbarIcon: NSImage(systemSymbolName: "textformat", accessibilityDescription: "Display")!
    ) {
        DisplaySettingsView()
    }
}
