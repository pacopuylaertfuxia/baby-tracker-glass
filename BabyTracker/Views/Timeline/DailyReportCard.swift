import SwiftUI

/// Timeline card — always shows, not expandable. Tap opens detail sheet.
/// Morning (<1pm) = "Sleep Report" with night stretch graph.
/// Evening (≥1pm) = "Day Report" with activity stat pills.
struct DailyReportCard: View {
    @Environment(TimelineStore.self) private var store
    @Environment(BabyStore.self) private var babyStore

    @State private var showDetail = false

    private enum ReportType {
        case sleep, day
    }

    private var reportType: ReportType {
        Calendar.current.component(.hour, from: .now) < 13 ? .sleep : .day
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    Text(reportType == .sleep ? "Sleep Report" : "Day Report")
                        .font(.keplerStat)
                        .foregroundStyle(.moonObsidian)

                    Spacer()

                    Text("Today →")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.moonClay)
                }

                Spacer().frame(height: 14)

                // Graph / stat pills
                if reportType == .sleep {
                    nightStretchGraph
                } else {
                    dayActivityBar
                }

                Spacer().frame(height: 10)

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.moonOlive)
                    .lineLimit(1)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.moonWhite)
                    .shadow(color: .moonBlack.opacity(0.06), radius: 16, y: 6)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .sheet(isPresented: $showDetail) {
            DailyReportDetail()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.moonCreme)
        }
    }

    // MARK: - Subtitle

    private var subtitle: String {
        switch reportType {
        case .sleep:
            let wakeCount = store.count([.nightWaking], daysAgo: 0)
            let longest = store.longestNightStretch
            if wakeCount == 0 {
                return "No wake-ups — slept through the night"
            }
            return "\(wakeCount) wake-up\(wakeCount == 1 ? "" : "s") · longest stretch \(formatDuration(longest))"

        case .day:
            let feedCount = store.countToday([.bottle, .nursing, .pumping, .solids])
            let napMinutes = Int(store.totalSleepToday / 60)
            let napStr = napMinutes >= 60 ? "\(napMinutes / 60)h \(napMinutes % 60)m" : "\(napMinutes)m"
            let diaperCount = store.countToday([.diaper])
            return "\(feedCount) feeds · \(napStr) naps · \(diaperCount) changes"
        }
    }

    // MARK: - Night stretch graph

    @ViewBuilder
    private var nightStretchGraph: some View {
        let wakes = store.nightWakes(daysAgo: 0).sorted { $0.timestamp < $1.timestamp }
        let cal = Calendar.current
        let now = Date.now
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let bedtime = cal.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!
        let morning = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        let totalNight = morning.timeIntervalSince(bedtime)

        if totalNight > 0 {
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    let w = geo.size.width
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.moonCreme)
                            .frame(height: 20)

                        ForEach(Array(sleepSegments(wakes: wakes, bedtime: bedtime, morning: morning, total: totalNight).enumerated()), id: \.offset) { _, seg in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(seg.isLongest ? Color.moonSleep : Color.moonSleep.opacity(0.4))
                                .frame(width: max(2, CGFloat(seg.fraction) * w - 2), height: 16)
                                .offset(x: CGFloat(seg.start) * w + 1)
                        }

                        ForEach(Array(wakes.enumerated()), id: \.offset) { _, wake in
                            let frac = wake.timestamp.timeIntervalSince(bedtime) / totalNight
                            Circle()
                                .fill(.moonWake)
                                .frame(width: 6, height: 6)
                                .offset(x: CGFloat(frac) * w - 3)
                        }
                    }
                }
                .frame(height: 20)

                HStack {
                    Text("8 PM")
                        .font(.system(size: 10))
                        .foregroundStyle(.moonStone)
                    Spacer()
                    if !wakes.isEmpty {
                        let longest = longestSegmentDuration(wakes: wakes, bedtime: bedtime, morning: morning)
                        Text("longest: \(formatDuration(longest))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.moonSleep)
                    }
                    Spacer()
                    Text("6 AM")
                        .font(.system(size: 10))
                        .foregroundStyle(.moonStone)
                }
            }
        }
    }

    // MARK: - Day activity bar (afternoon)

    @ViewBuilder
    private var dayActivityBar: some View {
        let feedCount = store.countToday([.bottle, .nursing, .pumping, .solids])
        let napCount = store.napCountToday
        let diaperCount = store.countToday([.diaper])

        HStack(spacing: 16) {
            statPill(icon: "icon_feed", count: feedCount, label: "feeds", color: .moonFood)
            statPill(icon: "icon_nap", count: napCount, label: "naps", color: .moonSleep)
            statPill(icon: "icon_diaper", count: diaperCount, label: "changes", color: .moonChange)
        }
    }

    private func statPill(icon: String, count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.moonObsidian)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.moonOlive)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
        }
    }

    // MARK: - Sleep segments helper

    private struct SleepSeg {
        let start: Double
        let fraction: Double
        let isLongest: Bool
    }

    private func sleepSegments(wakes: [TimelineEvent], bedtime: Date, morning: Date, total: TimeInterval) -> [SleepSeg] {
        let boundaries = [bedtime] + wakes.map(\.timestamp) + [morning]
        var longestDur: TimeInterval = 0
        var longestIdx = 0

        for i in 0..<(boundaries.count - 1) {
            let dur = boundaries[i + 1].timeIntervalSince(boundaries[i])
            if dur > longestDur {
                longestDur = dur
                longestIdx = i
            }
        }

        var segs: [SleepSeg] = []
        for i in 0..<(boundaries.count - 1) {
            let s = boundaries[i].timeIntervalSince(bedtime) / total
            let e = boundaries[i + 1].timeIntervalSince(bedtime) / total
            segs.append(SleepSeg(start: s, fraction: e - s, isLongest: i == longestIdx))
        }
        return segs
    }

    private func longestSegmentDuration(wakes: [TimelineEvent], bedtime: Date, morning: Date) -> TimeInterval {
        let boundaries = [bedtime] + wakes.map(\.timestamp) + [morning]
        var longest: TimeInterval = 0
        for i in 0..<(boundaries.count - 1) {
            longest = max(longest, boundaries[i + 1].timeIntervalSince(boundaries[i]))
        }
        return longest
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}
