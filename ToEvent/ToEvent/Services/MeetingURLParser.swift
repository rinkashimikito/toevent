import Foundation

struct MeetingURLParser {
    static let patterns: [(name: String, regex: String)] = [
        ("Zoom", #"https?://([a-z0-9]+\.)?zoom(gov)?\.us/(j|my|w)/[a-zA-Z0-9/?=&-]+"#),
        ("Google Meet", #"https?://meet\.google\.com/[a-z]+-[a-z]+-[a-z]+"#),
        ("Microsoft Teams", #"https?://teams\.microsoft\.com/l/meetup-join/[^\s]+"#),
        ("Webex", #"https?://([a-z0-9]+\.)?webex\.com/[^\s]+"#)
    ]

    /// Find meeting URL in text (notes, description, location)
    static func findMeetingURL(in text: String?) -> URL? {
        guard let text = text, !text.isEmpty else { return nil }

        for (_, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let urlString = String(text[range])
                return URL(string: urlString)
            }
        }
        return nil
    }

    /// Check multiple sources and return first meeting URL found
    static func findMeetingURL(url: URL?, location: String?, notes: String?) -> URL? {
        // Explicit URL takes priority if it looks like a meeting URL
        if let url = url, isMeetingURL(url) {
            return url
        }
        // Then check location field (often contains meeting URLs)
        if let found = findMeetingURL(in: location) {
            return found
        }
        // Finally check notes/description
        return findMeetingURL(in: notes)
    }

    /// Check if URL matches known meeting patterns
    static func isMeetingURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        return patterns.contains { _, pattern in
            (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))?
                .firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) != nil
        }
    }
}
