import Foundation

struct ActiveSession: Identifiable {
    let id: UUID
    let type: SessionType
    let startTime: Date
    let plannedDuration: TimeInterval?

    enum SessionType: String {
        case nap
        case monitor
        case motor

        var emoji: String {
            switch self {
            case .nap: return "😴"
            case .monitor: return "📹"
            case .motor: return "🌙"
            }
        }

        var label: String {
            switch self {
            case .nap: return "Napping"
            case .monitor: return "Streaming"
            case .motor: return "Sleep program"
            }
        }

        /// Short label for the collapsed session pill
        var sessionLabel: String {
            switch self {
            case .nap: return "Napping"
            case .monitor: return "Monitor"
            case .motor: return "Motor program"
            }
        }
    }

    var elapsed: TimeInterval {
        Date.now.timeIntervalSince(startTime)
    }

    var remaining: TimeInterval? {
        guard let planned = plannedDuration else { return nil }
        return max(0, planned - elapsed)
    }

    init(type: SessionType, plannedDuration: TimeInterval? = nil) {
        self.id = UUID()
        self.type = type
        self.startTime = .now
        self.plannedDuration = plannedDuration
    }
}
