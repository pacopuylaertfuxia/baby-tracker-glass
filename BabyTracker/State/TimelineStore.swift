import Foundation

@Observable
final class TimelineStore {
    var events: [TimelineEvent] = []

    init() {
        seedMockEvents()
    }

    func addEvent(_ event: TimelineEvent) {
        events.insert(event, at: 0)
    }

    // MARK: - Logging

    func logEvent(_ type: TimelineEvent.EventType) {
        addEvent(TimelineEvent(type: type, title: type.displayName))
    }

    func logDiaper() { logEvent(.diaper) }
    func logFeed() { logEvent(.bottle) }

    func logNap(duration: TimeInterval) {
        let mins = Int(duration / 60)
        addEvent(TimelineEvent(type: .nap, title: "Nap", subtitle: "\(mins) min"))
    }

    func logTemperature(_ value: String) {
        addEvent(TimelineEvent(type: .temperature, title: "Temperature", subtitle: value))
    }

    private func seedMockEvents() {
        let cal = Calendar.current
        let now = Date.now
        let today6am = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!

        events = [
            TimelineEvent(type: .wake, title: "Morning wake",
                          timestamp: cal.date(byAdding: .minute, value: 92, to: today6am)!),
            TimelineEvent(type: .nap, title: "Nap",
                          timestamp: cal.date(byAdding: .minute, value: 236, to: today6am)!,
                          endTime: cal.date(byAdding: .minute, value: 312, to: today6am)!),
            TimelineEvent(type: .diaper, title: "Diaper change",
                          timestamp: cal.date(byAdding: .minute, value: 342, to: today6am)!),
            TimelineEvent(type: .bottle, title: "Bottle",
                          timestamp: cal.date(byAdding: .minute, value: 452, to: today6am)!),
        ]
    }

    /// Segments for the day timeline bar (6am → 10pm)
    var timelineSegments: [TimelineSegment] {
        let cal = Calendar.current
        let now = Date.now
        let dayStart = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        let dayEnd = cal.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let totalSeconds = dayEnd.timeIntervalSince(dayStart)

        var segments: [TimelineSegment] = []

        // Add nap segments (sleep)
        for event in events where event.type == .nap {
            if let end = event.endTime {
                let start = max(event.timestamp, dayStart)
                let finish = min(end, dayEnd)
                segments.append(TimelineSegment(
                    startFraction: max(0, start.timeIntervalSince(dayStart) / totalSeconds),
                    endFraction: min(1, finish.timeIntervalSince(dayStart) / totalSeconds),
                    color: .moonSleep
                ))
            }
        }

        // Add point events (food, diaper, etc.) as dots
        let dotTypes: Set<TimelineEvent.EventType> = [.bottle, .nursing, .pumping, .solids, .diaper, .temperature, .medicine, .wake, .bedtime, .nightWaking]
        for event in events where dotTypes.contains(event.type) {
            let frac = event.timestamp.timeIntervalSince(dayStart) / totalSeconds
            if frac >= 0 && frac <= 1 {
                segments.append(TimelineSegment(
                    startFraction: frac,
                    endFraction: frac,
                    color: event.type.color,
                    isDot: true
                ))
            }
        }

        // Current time cursor
        let nowFrac = now.timeIntervalSince(dayStart) / totalSeconds
        if nowFrac >= 0 && nowFrac <= 1 {
            segments.append(TimelineSegment(
                startFraction: nowFrac,
                endFraction: nowFrac,
                color: .moonBlack,
                isCursor: true
            ))
        }

        return segments
    }
}

struct TimelineSegment {
    let startFraction: Double
    let endFraction: Double
    let color: SwiftUI.Color
    var isDot: Bool = false
    var isCursor: Bool = false
}

import SwiftUI
