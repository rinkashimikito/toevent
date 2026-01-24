import Foundation
import CoreGraphics

struct CachedEvents: Codable {
    let accountId: String
    let cachedAt: Date
    let events: [CodableEvent]
}

struct CodableEvent: Codable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColorHex: String
    let calendarID: String
    let calendarTitle: String
    let source: CalendarProviderType
    let accountId: String?
    let location: String?
    let meetingURL: String?
    let notes: String?
    let url: String?

    init(from event: Event) {
        self.id = event.id
        self.title = event.title
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.isAllDay = event.isAllDay
        self.calendarColorHex = event.calendarColor.hexString
        self.calendarID = event.calendarID
        self.calendarTitle = event.calendarTitle
        self.source = event.source
        self.accountId = event.accountId
        self.location = event.location
        self.meetingURL = event.meetingURL?.absoluteString
        self.notes = event.notes
        self.url = event.url?.absoluteString
    }

    func toEvent() -> Event {
        Event(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarColor: CGColor.fromHex(calendarColorHex) ?? CGColor(gray: 0.5, alpha: 1.0),
            calendarID: calendarID,
            calendarTitle: calendarTitle,
            source: source,
            accountId: accountId,
            location: location,
            meetingURL: meetingURL.flatMap { URL(string: $0) },
            notes: notes,
            url: url.flatMap { URL(string: $0) }
        )
    }
}

extension CGColor {
    var hexString: String {
        guard let components = components, components.count >= 3 else {
            return "#808080"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static func fromHex(_ hex: String) -> CGColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        return CGColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

final class EventCacheService {
    static let shared = EventCacheService()

    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let staleThreshold: TimeInterval = 86400 // 24 hours

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("com.toevent/events", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    func cacheEvents(_ events: [Event], for accountId: String) throws {
        let codableEvents = events.map { CodableEvent(from: $0) }
        let cached = CachedEvents(
            accountId: accountId,
            cachedAt: Date(),
            events: codableEvents
        )

        let fileURL = cacheFile(for: accountId)
        let data = try encoder.encode(cached)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadCachedEvents(for accountId: String) -> [Event] {
        let fileURL = cacheFile(for: accountId)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        guard let data = try? Data(contentsOf: fileURL),
              let cached = try? decoder.decode(CachedEvents.self, from: data) else {
            return []
        }

        let age = Date().timeIntervalSince(cached.cachedAt)
        if age > staleThreshold {
            print("Cache for \(accountId) is stale (\(Int(age / 3600))h old)")
        }

        return cached.events.map { $0.toEvent() }
    }

    func clearCache(for accountId: String) {
        let fileURL = cacheFile(for: accountId)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func clearAllCaches() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func cacheFile(for accountId: String) -> URL {
        let safeId = accountId.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent("\(safeId).json")
    }
}
