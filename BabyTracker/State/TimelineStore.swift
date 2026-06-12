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

    // MARK: - Queries

    /// Most recent event matching any of the given types
    func lastEvent(ofTypes types: Set<TimelineEvent.EventType>) -> TimelineEvent? {
        events.first { types.contains($0.type) }
    }

    /// Time interval since the most recent event of given types
    func timeSince(_ types: Set<TimelineEvent.EventType>) -> TimeInterval? {
        guard let event = lastEvent(ofTypes: types) else { return nil }
        return Date.now.timeIntervalSince(event.timestamp)
    }

    /// Last feeding event (any feeding type)
    var lastFeed: TimelineEvent? {
        lastEvent(ofTypes: [.bottle, .nursing, .pumping, .solids])
    }

    /// Last sleep-related event
    var lastSleep: TimelineEvent? {
        lastEvent(ofTypes: [.nap, .bedtime, .nightWaking, .wake])
    }

    /// Last diaper event
    var lastDiaper: TimelineEvent? {
        lastEvent(ofTypes: [.diaper])
    }

    /// Count of events today for a given set of types
    func countToday(_ types: Set<TimelineEvent.EventType>) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return events.filter { types.contains($0.type) && $0.timestamp >= startOfDay }.count
    }

    /// Count events of given types on a specific day offset (0 = today, -1 = yesterday, etc.)
    func count(_ types: Set<TimelineEvent.EventType>, daysAgo: Int) -> Int {
        let cal = Calendar.current
        let targetDay = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: .now))!
        let nextDay = cal.date(byAdding: .day, value: 1, to: targetDay)!
        return events.filter { types.contains($0.type) && $0.timestamp >= targetDay && $0.timestamp < nextDay }.count
    }

    /// Night wake events for a specific day offset
    func nightWakes(daysAgo: Int) -> [TimelineEvent] {
        let cal = Calendar.current
        let targetDay = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: .now))!
        let nextDay = cal.date(byAdding: .day, value: 1, to: targetDay)!
        return events.filter { $0.type == .nightWaking && $0.timestamp >= targetDay && $0.timestamp < nextDay }
            .sorted { $0.timestamp < $1.timestamp }
    }

    /// Total sleep duration today (from naps with endTime)
    var totalSleepToday: TimeInterval {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return events
            .filter { $0.type == .nap && $0.timestamp >= startOfDay }
            .compactMap { event -> TimeInterval? in
                guard let end = event.endTime else { return nil }
                return end.timeIntervalSince(event.timestamp)
            }
            .reduce(0, +)
    }

    private func seedMockEvents() {
        let cal = Calendar.current
        let now = Date.now
        let today6am = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!

        // Build a realistic day with varied events
        let minutesFromMorning = Int(now.timeIntervalSince(today6am) / 60)
        let clamp = { (m: Int) -> Date in
            cal.date(byAdding: .minute, value: min(m, minutesFromMorning - 5), to: today6am)!
        }

        // Today's events
        events = [
            TimelineEvent(type: .bottle, title: "Bottle", subtitle: "120 ml",
                          timestamp: clamp(452)),
            TimelineEvent(type: .diaper, title: "Diaper change",
                          timestamp: clamp(342)),
            TimelineEvent(type: .nap, title: "Nap", subtitle: "76 min",
                          timestamp: clamp(236),
                          endTime: clamp(312)),
            TimelineEvent(type: .nursing, title: "Nursing", subtitle: "15 min",
                          timestamp: clamp(200)),
            TimelineEvent(type: .diaper, title: "Diaper change",
                          timestamp: clamp(145)),
            TimelineEvent(type: .wake, title: "Morning wake",
                          timestamp: clamp(92)),
        ]

        // Night wakes — today (last night), yesterday, day before
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let dayBefore = cal.date(byAdding: .day, value: -2, to: now)!

        // Last night: 2 wakes
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Fussing",
                                    timestamp: cal.date(bySettingHour: 1, minute: 30, second: 0, of: now)!))
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Hungry",
                                    timestamp: cal.date(bySettingHour: 4, minute: 15, second: 0, of: now)!))

        // Yesterday night: 3 wakes
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Crying",
                                    timestamp: cal.date(bySettingHour: 0, minute: 45, second: 0, of: yesterday)!))
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Fussing",
                                    timestamp: cal.date(bySettingHour: 2, minute: 20, second: 0, of: yesterday)!))
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Hungry",
                                    timestamp: cal.date(bySettingHour: 5, minute: 0, second: 0, of: yesterday)!))

        // Day before: 1 wake
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Brief",
                                    timestamp: cal.date(bySettingHour: 3, minute: 10, second: 0, of: dayBefore)!))
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
