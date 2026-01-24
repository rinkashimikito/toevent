import SwiftUI

struct EventRowView: View {
    @EnvironmentObject private var appState: AppState
    let event: Event
    var onTap: () -> Void = {}

    @State private var isHovered = false
    @State private var showingDetail = false

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Button(action: onTap) {
            rowContent
        }
        .buttonStyle(EventRowButtonStyle(isHovered: isHovered, calendarColor: event.calendarColor))
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(cgColor: event.calendarColor))
                .frame(width: 8, height: 8)

            if appState.hasConflict(event) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .help("Overlaps with another event")
            }

            Text(truncatedTitle)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer()

            if isHovered {
                HStack(spacing: 4) {
                    if event.canJoinMeeting {
                        Button(action: { event.openMeetingURL() }) {
                            Image(systemName: "video.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Join meeting")
                    }

                    Button(action: { showingDetail = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("More actions")
                }
            } else {
                Text(timeDisplay)
                    .foregroundStyle(.secondary)
            }
        }
        .popover(isPresented: $showingDetail) {
            EventDetailView(event: event)
        }
    }

    private var truncatedTitle: String {
        if appState.privacyMode {
            return "Event"
        }
        if event.title.count > 30 {
            return String(event.title.prefix(30)) + "..."
        }
        return event.title
    }

    private var timeDisplay: String {
        if event.isAllDay {
            return "All day"
        }

        switch appState.timeDisplayFormat {
        case .countdown:
            return formatCountdown()
        case .absolute:
            return DateFormatters.formatAbsoluteTime(event.startDate)
        case .both:
            let countdown = formatCountdown()
            let absolute = DateFormatters.formatAbsoluteTime(event.startDate)
            return "\(countdown) (\(absolute))"
        }
    }

    private func formatCountdown() -> String {
        if appState.useNaturalLanguage {
            return DateFormatters.formatNaturalLanguage(until: event.startDate)
        }
        return DateFormatters.formatHybridCountdown(until: event.startDate)
    }
}

struct EventRowButtonStyle: ButtonStyle {
    let isHovered: Bool
    let calendarColor: CGColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(backgroundView(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        if isPressed {
            Color.accentColor.opacity(0.2)
        } else if isHovered {
            Color(cgColor: calendarColor).opacity(0.1)
        } else {
            Color.clear
        }
    }
}
