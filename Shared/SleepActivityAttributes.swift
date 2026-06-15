import ActivityKit
import Foundation

struct SleepActivityAttributes: ActivityAttributes {
    let babyName: String
    let sessionType: SessionKind

    enum SessionKind: String, Codable {
        case nap
        case bedtime
        case motor

        var icon: String {
            switch self {
            case .nap: "powersleep"
            case .bedtime: "moon.zzz.fill"
            case .motor: "moon.fill"
            }
        }

        var label: String {
            switch self {
            case .nap: "Napping"
            case .bedtime: "Sleeping"
            case .motor: "Motor"
            }
        }
    }

    struct ContentState: Codable, Hashable {
        let startTime: Date
        let isPaused: Bool
        let pausedElapsed: TimeInterval
        let wakeCount: Int

        // Motor-specific: countdown target
        let targetDuration: TimeInterval?
    }
}
