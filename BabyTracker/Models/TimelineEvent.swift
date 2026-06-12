import Foundation
import SwiftUI

struct TimelineEvent: Identifiable {
    let id: UUID
    let type: EventType
    let title: String
    let subtitle: String?
    let timestamp: Date
    let endTime: Date?

    enum EventType: String, CaseIterable {
        // Sleep
        case wake
        case nap
        case bedtime
        case nightWaking

        // Feeding
        case bottle
        case nursing
        case pumping
        case solids

        // Care
        case diaper
        case temperature
        case medicine

        // Devices (non-trackable, session-based)
        case motor
        case monitor

        var imageName: String? {
            switch self {
            case .wake: return "icon_sun"
            case .nap: return "icon_nap"
            case .bedtime: return "icon_bedtime"
            case .nightWaking: return "icon_night_waking"
            case .bottle: return "icon_feed"
            case .nursing: return "icon_nursing"
            case .pumping: return "icon_pumping"
            case .solids: return "icon_solids"
            case .diaper: return "icon_diaper"
            case .temperature: return "icon_temperature"
            case .medicine: return "icon_medicine"
            case .motor: return "icon_moon"
            case .monitor: return nil
            }
        }

        var sfSymbol: String {
            switch self {
            case .wake: return "sun.max.fill"
            case .nap: return "powersleep"
            case .bedtime: return "moon.fill"
            case .nightWaking: return "moon.zzz.fill"
            case .bottle: return "waterbottle.fill"
            case .nursing: return "heart.fill"
            case .pumping: return "drop.fill"
            case .solids: return "fork.knife"
            case .diaper: return "sparkles"
            case .temperature: return "thermometer.medium"
            case .medicine: return "pill.fill"
            case .motor: return "moon.fill"
            case .monitor: return "video.fill"
            }
        }

        var displayName: String {
            switch self {
            case .wake: return "Woke up"
            case .nap: return "Nap"
            case .bedtime: return "Bedtime"
            case .nightWaking: return "Night waking"
            case .bottle: return "Bottle"
            case .nursing: return "Nursing"
            case .pumping: return "Pumping"
            case .solids: return "Solids"
            case .diaper: return "Diaper change"
            case .temperature: return "Temperature"
            case .medicine: return "Medicine"
            case .motor: return "Motor"
            case .monitor: return "Monitor"
            }
        }

        var color: Color {
            switch self {
            case .wake: return .moonWake
            case .nap, .bedtime, .nightWaking: return .moonSleep
            case .bottle, .nursing, .pumping, .solids: return .moonFood
            case .diaper: return .moonChange
            case .temperature: return .moonClay
            case .medicine: return .moonInfo
            case .motor: return .moonClay
            case .monitor: return .moonInfo
            }
        }

        /// Categories the user can log (excludes device sessions)
        static var trackable: [EventType] {
            [.wake, .nap, .bedtime, .nightWaking, .bottle, .nursing, .pumping, .solids, .diaper, .temperature, .medicine]
        }

        var emoji: String {
            switch self {
            case .wake: return "🌅"
            case .nap: return "😴"
            case .bedtime: return "🌙"
            case .nightWaking: return "🌜"
            case .bottle: return "🍼"
            case .nursing: return "🤱"
            case .pumping: return "💧"
            case .solids: return "🥣"
            case .diaper: return "🧷"
            case .temperature: return "🌡️"
            case .medicine: return "💊"
            case .motor: return "🌙"
            case .monitor: return "📹"
            }
        }

        /// Group label for the tracking sheet
        var category: String {
            switch self {
            case .wake, .nap, .bedtime, .nightWaking: return "Sleep"
            case .bottle, .nursing, .pumping, .solids: return "Feeding"
            case .diaper, .temperature, .medicine: return "Care"
            case .motor, .monitor: return "Devices"
            }
        }
    }

    init(type: EventType, title: String, subtitle: String? = nil, timestamp: Date = .now, endTime: Date? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.timestamp = timestamp
        self.endTime = endTime
    }
}
