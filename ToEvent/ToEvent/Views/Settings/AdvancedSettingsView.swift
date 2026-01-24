import SwiftUI

struct AdvancedSettingsView: View {
    @EnvironmentObject private var appState: AppState

    private let fetchIntervalOptions: [(String, TimeInterval)] = [
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300),
        ("10 minutes", 600),
        ("15 minutes", 900),
        ("30 minutes", 1800)
    ]

    private let eventCountOptions = [5, 10, 15, 20, 25]

    var body: some View {
        Form {
            Section("Urgency Thresholds") {
                thresholdRow(
                    label: "Red (imminent):",
                    value: Binding(
                        get: { appState.urgencyThresholds.imminent },
                        set: { appState.urgencyThresholds.imminent = $0 }
                    ),
                    range: 60...(appState.urgencyThresholds.soon - 60)
                )
                thresholdRow(
                    label: "Orange (soon):",
                    value: Binding(
                        get: { appState.urgencyThresholds.soon },
                        set: { appState.urgencyThresholds.soon = $0 }
                    ),
                    range: (appState.urgencyThresholds.imminent + 60)...(appState.urgencyThresholds.approaching - 60)
                )
                thresholdRow(
                    label: "Yellow (approaching):",
                    value: Binding(
                        get: { appState.urgencyThresholds.approaching },
                        set: { appState.urgencyThresholds.approaching = $0 }
                    ),
                    range: (appState.urgencyThresholds.soon + 60)...7200
                )
                Button("Reset to Defaults") {
                    appState.urgencyThresholds = .default
                }
                .buttonStyle(.link)
            }

            Section("Calendar Sync") {
                Picker("Fetch interval:", selection: $appState.fetchInterval) {
                    ForEach(fetchIntervalOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                Text("More frequent fetching uses more battery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Event List") {
                Picker("Maximum events:", selection: $appState.maxEventsToShow) {
                    ForEach(eventCountOptions, id: \.self) { count in
                        Text("\(count) events").tag(count)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func thresholdRow(label: String, value: Binding<TimeInterval>, range: ClosedRange<TimeInterval>) -> some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)
            Stepper(
                formatMinutes(value.wrappedValue),
                value: value,
                in: range,
                step: 60
            )
        }
    }

    private func formatMinutes(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }
}

extension AdvancedSettingsView {
    static let pane: SettingsPane = SettingsPane(
        identifier: SettingsPaneIdentifier("advanced"),
        title: "Advanced",
        toolbarIcon: NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: "Advanced")!
    ) {
        AdvancedSettingsView()
    }
}
