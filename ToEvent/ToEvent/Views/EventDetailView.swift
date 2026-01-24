import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    @State private var travelTime: TimeInterval?
    @State private var leaveTime: Date?
    @State private var isLoadingTravelTime = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let leaveTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            timeSection
            if let location = event.location, !location.isEmpty {
                locationSection(location)
                travelSection
            }
            calendarSection
            if let notes = event.notes, !notes.isEmpty {
                notesSection(notes)
            }
            Divider()
            actionButtons
        }
        .padding()
        .frame(width: 320)
        .task {
            if let location = event.location, !location.isEmpty {
                isLoadingTravelTime = true
                travelTime = await TravelTimeService.shared.calculateTravelTime(to: location)
                leaveTime = await TravelTimeService.shared.calculateLeaveTime(for: event)
                isLoadingTravelTime = false
            }
        }
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(Color(cgColor: event.calendarColor))
                .frame(width: 12, height: 12)

            Text(event.title)
                .font(.headline)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var timeSection: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.secondary)
                .frame(width: 20)

            if event.isAllDay {
                Text("All day")
            } else {
                Text(Self.timeFormatter.string(from: event.startDate))
            }
        }
    }

    private func locationSection(_ location: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "location")
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(location)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private var travelSection: some View {
        HStack(alignment: .top) {
            Image(systemName: "car")
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                if isLoadingTravelTime {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Calculating travel time...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let travelTime = travelTime {
                    Text("Travel: \(TravelTimeService.shared.formatTravelTime(travelTime))")
                        .font(.callout)

                    if let leaveTime = leaveTime {
                        Text("Leave by \(Self.leaveTimeFormatter.string(from: leaveTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Travel time unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var calendarSection: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(event.calendarTitle)
                .foregroundColor(.secondary)
        }
    }

    private func notesSection(_ notes: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "note.text")
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(notes.prefix(150) + (notes.count > 150 ? "..." : ""))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if event.canJoinMeeting {
                Button(action: { event.openMeetingURL() }) {
                    Label("Join", systemImage: "video")
                }
                .buttonStyle(.borderedProminent)
            }

            if event.canGetDirections {
                Button(action: { event.openInMaps() }) {
                    Label("Directions", systemImage: "map")
                }
                .buttonStyle(.bordered)
            }

            Button(action: { event.copyToClipboard() }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }
}
