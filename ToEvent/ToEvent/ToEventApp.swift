import SwiftUI
import Settings
import EventKit
import MenuBarExtraAccess
import AppKit
import KeyboardShortcuts
import Sparkle

final class ShortcutHandler: ObservableObject {
    @Published var isMenuPresented = false

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleDropdown) { [weak self] in
            self?.isMenuPresented.toggle()
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var appState: AppState
    var onUpdate: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if appState.showMenuBarIcon {
                Image(systemName: "calendar")
            }
            if appState.menuBarTitle != "ToEvent" {
                Text(appState.menuBarTitle)
            } else if appState.showMenuBarIcon {
                EmptyView()
            } else {
                Text("ToEvent")
            }
        }
        .onChange(of: appState.menuBarTitle) { _ in
            onUpdate()
        }
        .onChange(of: appState.currentTime) { _ in
            onUpdate()
        }
        .onChange(of: appState.nextEvent?.id) { _ in
            onUpdate()
        }
        .onChange(of: appState.showMenuBarIcon) { _ in
            onUpdate()
        }
        .onAppear {
            // Delay to ensure statusItem is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onUpdate()
            }
        }
    }
}

@main
struct ToEventApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var shortcutHandler = ShortcutHandler()
    @StateObject private var updaterController = UpdaterController()
    @State private var statusItem: NSStatusItem?
    @State private var showWhatsNew = false

    init() {
        NotificationService.shared.setup()
    }

    private var needsPermission: Bool {
        let status = CalendarService.shared.authorizationStatus()
        return status == .notDetermined || status == .denied || status == .restricted
    }

    var body: some Scene {
        MenuBarExtra {
            Group {
                if appState.hasCompletedIntro && !needsPermission {
                    MenuBarView()
                        .environmentObject(appState)
                        .onAppear {
                            appState.refreshEvents()
                        }
                } else {
                    IntroView()
                        .environmentObject(appState)
                }
            }
            .onAppear {
                if WhatsNewCheck.shouldShowWhatsNew() {
                    showWhatsNew = true
                }
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewView()
            }
        } label: {
            MenuBarLabel(appState: appState) {
                if let item = statusItem {
                    applyUrgencyAppearance(to: item)
                }
            }
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $shortcutHandler.isMenuPresented) { item in
            statusItem = item
            applyUrgencyAppearance(to: item)
        }

        SwiftUI.Settings {
            TabView {
                GeneralSettingsView()
                    .tabItem { Label("General", systemImage: "gear") }
                DisplaySettingsView()
                    .tabItem { Label("Display", systemImage: "textformat") }
                NotificationSettingsView()
                    .tabItem { Label("Notifications", systemImage: "bell") }
                CalendarSettingsView()
                    .tabItem { Label("Calendars", systemImage: "calendar") }
                AdvancedSettingsView()
                    .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
            }
            .environmentObject(appState)
            .environmentObject(updaterController)
            .frame(width: 500, height: 400)
        }
    }

    private func applyUrgencyAppearance(to statusItem: NSStatusItem) {
        guard let event = appState.nextEvent, !event.isAllDay else {
            if appState.showMenuBarIcon {
                let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "ToEvent")
                image?.isTemplate = true
                statusItem.button?.image = image
                statusItem.button?.attributedTitle = NSAttributedString(string: "")
            } else {
                statusItem.button?.image = nil
                statusItem.button?.attributedTitle = NSAttributedString(string: "ToEvent")
            }
            return
        }

        let urgency = appState.urgencyLevel
        let title = appState.menuBarTitle

        let textAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: urgency.color,
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: title, attributes: textAttrs)

        if appState.showMenuBarIcon {
            let iconName = urgency.iconFilled ? "calendar.circle.fill" : "calendar"
            if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "ToEvent") {
                if urgency >= .approaching {
                    image.isTemplate = false
                    let config = NSImage.SymbolConfiguration(paletteColors: [urgency.color])
                    statusItem.button?.image = image.withSymbolConfiguration(config)
                } else {
                    image.isTemplate = true
                    statusItem.button?.image = image
                }
            }
        } else {
            statusItem.button?.image = nil
        }
    }
}
