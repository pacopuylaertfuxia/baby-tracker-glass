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

    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
    }

    // MARK: - Logging

    func logEvent(_ type: TimelineEvent.EventType) {
        addEvent(TimelineEvent(type: type, title: type.displayName))
    }

    func logDiaper() { logEvent(.diaper) }
    func logFeed() { logEvent(.bottle) }

    func logNap(duration: TimeInterval) {
        let mins = Int(duration / 60)
        let end = Date.now
        let start = end.addingTimeInterval(-duration)
        addEvent(TimelineEvent(type: .nap, title: "Nap", subtitle: "\(mins) min",
                                timestamp: start, endTime: end))
    }

    func logTemperature(_ value: String) {
        addEvent(TimelineEvent(type: .temperature, title: "Temperature", subtitle: value))
    }

    func logNightWake(subtitle: String? = nil, audioURL: URL? = nil, wakeDuration: TimeInterval? = nil) {
        addEvent(TimelineEvent(type: .nightWaking, title: "Night waking",
                               subtitle: subtitle, audioURL: audioURL, wakeDuration: wakeDuration))
    }

    func logBedtime() {
        addEvent(TimelineEvent(type: .bedtime, title: "Bedtime"))
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

    /// Count of nap events today
    var napCountToday: Int {
        countToday([.nap])
    }

    /// Longest stretch between consecutive night wakes (or bedtime→first wake)
    var longestNightStretch: TimeInterval {
        let cal = Calendar.current
        let now = Date.now
        // Look at wakes from last night (today's calendar day, early hours)
        let wakes = nightWakes(daysAgo: 0).sorted { $0.timestamp < $1.timestamp }

        // Assume bedtime was around 8pm yesterday
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let bedtime = cal.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!

        if wakes.isEmpty {
            // No wakes — full stretch from bedtime to 6am
            let wakeUp = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
            return wakeUp.timeIntervalSince(bedtime)
        }

        var longest: TimeInterval = 0

        // Bedtime → first wake
        longest = max(longest, wakes[0].timestamp.timeIntervalSince(bedtime))

        // Between consecutive wakes
        for i in 1..<wakes.count {
            let gap = wakes[i].timestamp.timeIntervalSince(wakes[i - 1].timestamp)
            longest = max(longest, gap)
        }

        // Last wake → morning (6am)
        let morning = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        if wakes.last!.timestamp < morning {
            longest = max(longest, morning.timeIntervalSince(wakes.last!.timestamp))
        }

        return longest
    }

    // MARK: - Daily Report queries

    /// Estimated total night sleep (10h window minus estimated wake time)
    var totalNightSleep: TimeInterval {
        let cal = Calendar.current
        let now = Date.now
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let bedtime = cal.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!
        let morning = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        let totalWindow = morning.timeIntervalSince(bedtime) // 10h

        let wakes = nightWakes(daysAgo: 0)
        // Estimate ~15min awake per wake event
        let awakeTime = Double(wakes.count) * 15 * 60
        return max(0, totalWindow - awakeTime)
    }

    /// Sleep trend comparing last 3 nights' longest stretch
    enum SleepTrend {
        case improving, same, declining
    }

    var sleepTrend: SleepTrend {
        let stretches = (0...2).map { longestStretch(daysAgo: $0) }
        // stretches[0] = tonight, stretches[1] = last night, stretches[2] = night before
        let recent = stretches[0]
        let avg = stretches.dropFirst().reduce(0, +) / Double(max(1, stretches.count - 1))
        if avg == 0 { return .same }
        let diff = (recent - avg) / avg
        if diff > 0.15 { return .improving }
        if diff < -0.15 { return .declining }
        return .same
    }

    /// Longest stretch for a specific night (by daysAgo)
    func longestStretch(daysAgo: Int) -> TimeInterval {
        let cal = Calendar.current
        let now = Date.now
        let targetDay = cal.date(byAdding: .day, value: -daysAgo, to: now)!
        let prevDay = cal.date(byAdding: .day, value: -1, to: targetDay)!
        let bedtime = cal.date(bySettingHour: 20, minute: 0, second: 0, of: prevDay)!
        let morning = cal.date(bySettingHour: 6, minute: 0, second: 0, of: targetDay)!

        let wakes = nightWakes(daysAgo: daysAgo).sorted { $0.timestamp < $1.timestamp }
        if wakes.isEmpty {
            return morning.timeIntervalSince(bedtime)
        }

        var longest: TimeInterval = wakes[0].timestamp.timeIntervalSince(bedtime)
        for i in 1..<wakes.count {
            longest = max(longest, wakes[i].timestamp.timeIntervalSince(wakes[i - 1].timestamp))
        }
        if wakes.last!.timestamp < morning {
            longest = max(longest, morning.timeIntervalSince(wakes.last!.timestamp))
        }
        return longest
    }

    /// Rolling average night wake count over N days
    func averageNightWakes(days: Int) -> Double {
        guard days > 0 else { return 0 }
        let total = (0..<days).map { count([.nightWaking], daysAgo: $0) }.reduce(0, +)
        return Double(total) / Double(days)
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

    // MARK: - Night Report Builder

    /// Build a NightReport from events. daysAgo=0 means last night (the night ending today).
    func nightReport(daysAgo: Int = 0) -> NightReport? {
        let cal = Calendar.current
        let today = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: .now))!
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        // Find bedtime event from yesterday evening, or assume 8pm
        let bedtimeEvent = events.first {
            $0.type == .bedtime && cal.isDate($0.timestamp, inSameDayAs: yesterday) && cal.component(.hour, from: $0.timestamp) >= 18
        }
        let bedtime = bedtimeEvent?.timestamp ?? cal.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!

        // Find wake event from today morning, or assume 6am
        let wakeEvent = events.first {
            $0.type == .wake && cal.isDate($0.timestamp, inSameDayAs: today) && cal.component(.hour, from: $0.timestamp) < 12
        }
        let wakeTime = wakeEvent?.timestamp ?? cal.date(bySettingHour: 6, minute: 0, second: 0, of: today)!

        // Get night wakes between bedtime and wake time, sorted
        let wakes = events.filter {
            $0.type == .nightWaking && $0.timestamp > bedtime && $0.timestamp < wakeTime
        }.sorted { $0.timestamp < $1.timestamp }

        // No wakes AND no bedtime event AND no wake event → no report
        if bedtimeEvent == nil && wakeEvent == nil && wakes.isEmpty {
            // Still show report if we have mock night wakes for this day
            let hasNightData = !nightWakes(daysAgo: daysAgo).isEmpty
            if !hasNightData { return nil }
        }

        // Build segments
        var segments: [NightSegment] = []
        var cursor = bedtime

        for wake in wakes {
            // Sleep segment: cursor → wake start
            if wake.timestamp > cursor {
                segments.append(NightSegment(
                    start: cursor, end: wake.timestamp, isSleep: true, reason: nil
                ))
            }

            // Wake segment: use wakeDuration if available, otherwise estimate from gap to next event
            let wakeDur: TimeInterval
            if let dur = wake.wakeDuration, dur > 0 {
                wakeDur = dur
            } else {
                // Estimate: gap to next event, capped at 15 min
                let nextTime = wakes.first(where: { $0.timestamp > wake.timestamp })?.timestamp ?? wakeTime
                wakeDur = min(nextTime.timeIntervalSince(wake.timestamp), 15 * 60)
            }

            let wakeEnd = wake.timestamp.addingTimeInterval(wakeDur)
            segments.append(NightSegment(
                start: wake.timestamp,
                end: min(wakeEnd, wakeTime),
                isSleep: false,
                reason: wake.subtitle
            ))
            cursor = min(wakeEnd, wakeTime)
        }

        // Final sleep segment: last cursor → wake time
        if cursor < wakeTime {
            segments.append(NightSegment(
                start: cursor, end: wakeTime, isSleep: true, reason: nil
            ))
        }

        return NightReport(
            bedtime: bedtime,
            wakeTime: wakeTime,
            segments: segments,
            wakeCount: wakes.count
        )
    }

    /// Last night's report (the night that ended today)
    var lastNightReport: NightReport? { nightReport(daysAgo: 0) }

    /// Previous night's report (for trend comparison)
    var previousNightReport: NightReport? { nightReport(daysAgo: 1) }

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

        // Bedtime last night
        events.append(TimelineEvent(type: .bedtime, title: "Bedtime",
                                    timestamp: cal.date(bySettingHour: 20, minute: 30, second: 0, of: yesterday)!))

        // Last night: 2 wakes (with wakeDuration)
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Fussing",
                                    timestamp: cal.date(bySettingHour: 1, minute: 30, second: 0, of: now)!,
                                    wakeDuration: 8 * 60))
        events.append(TimelineEvent(type: .nightWaking, title: "Night waking", subtitle: "Hungry",
                                    timestamp: cal.date(bySettingHour: 4, minute: 15, second: 0, of: now)!,
                                    wakeDuration: 12 * 60))

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

// MARK: - Night Report

struct NightSegment: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let isSleep: Bool
    let reason: String?

    var duration: TimeInterval { end.timeIntervalSince(start) }
}

struct NightReport {
    let bedtime: Date
    let wakeTime: Date
    let segments: [NightSegment]
    let wakeCount: Int

    var totalNight: TimeInterval { wakeTime.timeIntervalSince(bedtime) }

    var totalSleep: TimeInterval {
        segments.filter(\.isSleep).reduce(0) { $0 + $1.duration }
    }

    var longestStretch: TimeInterval {
        segments.filter(\.isSleep).map(\.duration).max() ?? 0
    }

    var longestStretchSegment: NightSegment? {
        segments.filter(\.isSleep).max(by: { $0.duration < $1.duration })
    }

    var avgWakeDuration: TimeInterval {
        let wakes = segments.filter { !$0.isSleep }
        guard !wakes.isEmpty else { return 0 }
        return wakes.reduce(0) { $0 + $1.duration } / Double(wakes.count)
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
