import AppKit

struct UrgencyThresholds: Equatable {
    var imminent: TimeInterval    // seconds, default 300 (5 min) - red
    var soon: TimeInterval        // seconds, default 900 (15 min) - orange
    var approaching: TimeInterval // seconds, default 1800 (30 min) - yellow

    static let `default` = UrgencyThresholds(
        imminent: 300,
        soon: 900,
        approaching: 1800
    )

    var isValid: Bool {
        imminent < soon && soon < approaching
    }
}

enum UrgencyLevel: Comparable {
    case normal      // > approaching threshold
    case approaching // <= approaching (yellow)
    case soon        // <= soon (orange)
    case imminent    // <= imminent (red)
    case now         // event started

    static func from(secondsRemaining: TimeInterval) -> UrgencyLevel {
        from(secondsRemaining: secondsRemaining, thresholds: .default)
    }

    static func from(secondsRemaining: TimeInterval, thresholds: UrgencyThresholds) -> UrgencyLevel {
        switch secondsRemaining {
        case ...0: return .now
        case 0..<thresholds.imminent: return .imminent
        case thresholds.imminent..<thresholds.soon: return .soon
        case thresholds.soon..<thresholds.approaching: return .approaching
        default: return .normal
        }
    }

    var color: NSColor {
        switch self {
        case .normal: return .labelColor
        case .approaching: return .systemYellow
        case .soon: return .systemOrange
        case .imminent, .now: return .systemRed
        }
    }

    var iconFilled: Bool {
        self >= .soon
    }
}
