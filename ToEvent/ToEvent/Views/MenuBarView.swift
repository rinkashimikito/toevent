import SwiftUI
import AppKit
import Settings

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isRefreshing = false
    @State private var showingQuickAdd = false

    var body: some View {
        VStack(spacing: 0) {
            EventListView(onEventTap: openEventInCalendar)

            Divider()

            footerBar
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var footerBar: some View {
        HStack {
            settingsButton

            Spacer()

            Button(action: { showingQuickAdd = true }) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
            .help("Quick add event")
            .popover(isPresented: $showingQuickAdd) {
                QuickAddView()
            }

            Button(action: refresh) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .help("Settings")
            .simultaneousGesture(TapGesture().onEnded {
                NSApp.activate(ignoringOtherApps: true)
            })
        } else {
            Button(action: openSettings) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }

    private func refresh() {
        withAnimation(.linear(duration: 0.5)) {
            isRefreshing = true
        }
        appState.refreshEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
    }

    private func openEventInCalendar(_ event: Event) {
        let timestamp = Int(event.startDate.timeIntervalSinceReferenceDate)
        if let url = URL(string: "ical://showdate/\(timestamp)") {
            NSWorkspace.shared.open(url)
        }
    }
}
