import AppKit

extension Event {
    // MARK: - Computed Properties

    var canJoinMeeting: Bool {
        meetingURL != nil
    }

    var canGetDirections: Bool {
        guard let location = location, !location.isEmpty else { return false }
        return true
    }

    // MARK: - Actions

    func openMeetingURL() {
        guard let url = meetingURL else { return }
        NSWorkspace.shared.open(url)
    }

    func openInMaps() {
        guard let location = location, !location.isEmpty else { return }

        let encodedAddress = location.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? location

        if let url = URL(string: "maps://?daddr=\(encodedAddress)") {
            NSWorkspace.shared.open(url)
        }
    }

    func copyToClipboard() {
        var details = title

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if isAllDay {
            formatter.timeStyle = .none
            details += "\n\(formatter.string(from: startDate)) (All day)"
        } else {
            details += "\n\(formatter.string(from: startDate))"
        }

        if let location = location, !location.isEmpty {
            details += "\nLocation: \(location)"
        }

        if let meetingURL = meetingURL {
            details += "\nMeeting: \(meetingURL.absoluteString)"
        }

        if let notes = notes, !notes.isEmpty {
            let excerpt = notes.prefix(200)
            details += "\n\n\(excerpt)\(notes.count > 200 ? "..." : "")"
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(details, forType: .string)
    }

    func openInCalendar() {
        guard source == .local else { return }

        let script = """
        tell application "Calendar"
            activate
            view calendar at date "\(formattedDateForAppleScript)"
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }

    private var formattedDateForAppleScript: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: startDate)
    }
}
