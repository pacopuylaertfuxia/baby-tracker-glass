import SwiftUI

/// Full-screen sheet with 3 sections: breakdown, insights, and recommended reading.
struct DailyReportDetail: View {
    @Environment(TimelineStore.self) private var store
    @Environment(BabyStore.self) private var babyStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private enum ReportType {
        case sleep, day
    }

    private var reportType: ReportType {
        Calendar.current.component(.hour, from: .now) < 13 ? .sleep : .day
    }

    private var ageWeeks: Int {
        let days = Calendar.current.dateComponents([.day], from: babyStore.baby.birthDate, to: .now).day ?? 0
        return days / 7
    }

    private var name: String { babyStore.baby.name }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.moonOlive)
                            .frame(width: 32, height: 32)
                            .background(.moonWhite, in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Title
                Text(reportType == .sleep ? "Sleep Report" : "Day Report")
                    .font(.kepler(32))
                    .foregroundStyle(.moonObsidian)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // Section 1 — Breakdown
                Spacer().frame(height: 24)
                sectionHeader("BREAKDOWN")
                Spacer().frame(height: 12)

                if reportType == .sleep {
                    nightBreakdown
                } else {
                    dayBreakdown
                }

                // Section 2 — Insights
                Spacer().frame(height: 32)
                sectionHeader("INSIGHTS")
                Spacer().frame(height: 12)
                insightsSection

                // Section 3 — Recommended Reading
                Spacer().frame(height: 32)
                sectionHeader("RECOMMENDED READING")
                Spacer().frame(height: 12)
                readingSection

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.moonClay)
            .tracking(0.6)
            .padding(.horizontal, 24)
    }

    // MARK: - Section 1: Night Breakdown

    @ViewBuilder
    private var nightBreakdown: some View {
        let wakes = store.nightWakes(daysAgo: 0).sorted { $0.timestamp < $1.timestamp }
        let cal = Calendar.current
        let now = Date.now
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        let bedtime = cal.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!
        let morning = cal.date(bySettingHour: 6, minute: 0, second: 0, of: now)!
        let totalNight = morning.timeIntervalSince(bedtime)

        VStack(alignment: .leading, spacing: 16) {
            // Larger night stretch graph
            if totalNight > 0 {
                nightGraph(wakes: wakes, bedtime: bedtime, morning: morning, totalNight: totalNight)
                    .padding(.horizontal, 24)
            }

            // Stat cards row
            HStack(spacing: 12) {
                statCard(
                    value: formatDuration(store.totalNightSleep),
                    label: "Total sleep"
                )
                statCard(
                    value: "\(wakes.count)",
                    label: "Wake-ups"
                )
                statCard(
                    value: formatDuration(store.longestNightStretch),
                    label: "Longest stretch"
                )
            }
            .padding(.horizontal, 16)

            // Wake timeline
            if !wakes.isEmpty {
                VStack(spacing: 8) {
                    ForEach(wakes) { wake in
                        wakeRow(wake)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func nightGraph(wakes: [TimelineEvent], bedtime: Date, morning: Date, totalNight: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.moonCreme)
                        .frame(height: 40)

                    ForEach(Array(sleepSegments(wakes: wakes, bedtime: bedtime, morning: morning, total: totalNight).enumerated()), id: \.offset) { _, seg in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(seg.isLongest ? Color.moonSleep : Color.moonSleep.opacity(0.4))
                            .frame(width: max(4, CGFloat(seg.fraction) * w - 4), height: 34)
                            .offset(x: CGFloat(seg.start) * w + 2)
                    }

                    ForEach(Array(wakes.enumerated()), id: \.offset) { _, wake in
                        let frac = wake.timestamp.timeIntervalSince(bedtime) / totalNight
                        Circle()
                            .fill(.moonWake)
                            .frame(width: 10, height: 10)
                            .offset(x: CGFloat(frac) * w - 5)
                    }
                }
            }
            .frame(height: 40)

            HStack {
                Text("8 PM")
                    .font(.system(size: 10))
                    .foregroundStyle(.moonStone)
                Spacer()
                Text("6 AM")
                    .font(.system(size: 10))
                    .foregroundStyle(.moonStone)
            }
        }
    }

    // MARK: - Section 1: Day Breakdown

    @ViewBuilder
    private var dayBreakdown: some View {
        let feedCount = store.countToday([.bottle, .nursing, .pumping, .solids])
        let napMinutes = Int(store.totalSleepToday / 60)
        let napStr = napMinutes >= 60 ? "\(napMinutes / 60)h \(napMinutes % 60)m" : "\(napMinutes)m"
        let diaperCount = store.countToday([.diaper])

        VStack(alignment: .leading, spacing: 16) {
            // Stat cards row
            HStack(spacing: 12) {
                statCard(value: "\(feedCount)", label: "Feeds")
                statCard(value: napStr, label: "Nap time")
                statCard(value: "\(diaperCount)", label: "Diapers")
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Stat Card

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.keplerStat)
                .foregroundStyle(.moonObsidian)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.moonClay)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Wake Row

    private func wakeRow(_ event: TimelineEvent) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(formatTime(event.timestamp))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.moonObsidian)
                    .monospacedDigit()
                Text(ampm(event.timestamp))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.moonClay)
            }
            .frame(width: 52)

            RoundedRectangle(cornerRadius: 2)
                .fill(.moonSleep)
                .frame(width: 3, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Night waking")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.moonObsidian)
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.moonClay)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.03), radius: 6, y: 2)
        }
    }

    // MARK: - Section 2: Insights

    @ViewBuilder
    private var insightsSection: some View {
        let insights = generateInsights()
        let actions = generateActions()

        VStack(alignment: .leading, spacing: 12) {
            // "What we noticed"
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What we noticed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.moonObsidian)
                        .padding(.horizontal, 24)

                    ForEach(Array(insights.enumerated()), id: \.offset) { _, text in
                        insightRow(text)
                    }
                }
            }

            Spacer().frame(height: 8)

            // Action points
            if !actions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(reportType == .sleep ? "Try tonight" : "Try tomorrow")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.moonObsidian)
                        .padding(.horizontal, 24)

                    ForEach(Array(actions.enumerated()), id: \.offset) { _, text in
                        insightRow(text, accent: .moonFood)
                    }
                }
            }
        }
    }

    private func insightRow(_ text: String, accent: Color = .moonClay) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 3, height: 36)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.moonOlive)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Insights Logic (rule-based)

    private func generateInsights() -> [String] {
        var pool: [(priority: Int, text: String)] = []
        let weeks = ageWeeks

        if reportType == .sleep {
            let wakeCount = store.count([.nightWaking], daysAgo: 0)
            let avg = store.averageNightWakes(days: 3)
            let trend = store.sleepTrend
            let longest = store.longestNightStretch

            if wakeCount == 0 {
                pool.append((10, "No wake-ups at all — that's exceptional at \(weeks) weeks. Her body is figuring it out."))
            } else if Double(wakeCount) < avg - 0.3 {
                pool.append((8, "Fewer wake-ups than her recent average — that's progress."))
            } else if Double(wakeCount) > avg + 0.3 {
                pool.append((8, "A few more wakes than usual. Growth spurts and developmental leaps can cause this — it's temporary."))
            }

            if trend == .improving {
                pool.append((7, "Her longest stretch has been getting longer — her sleep cycles are maturing."))
            }

            // Evenly spaced wakes
            let wakes = store.nightWakes(daysAgo: 0).sorted { $0.timestamp < $1.timestamp }
            if wakes.count >= 2 {
                let gaps = (1..<wakes.count).map { wakes[$0].timestamp.timeIntervalSince(wakes[$0 - 1].timestamp) }
                let avgGap = gaps.reduce(0, +) / Double(gaps.count)
                let maxDev = gaps.map { abs($0 - avgGap) }.max() ?? 0
                if maxDev < avgGap * 0.3 {
                    let gapH = Int(avgGap / 3600)
                    let gapM = (Int(avgGap) % 3600) / 60
                    let gapStr = gapH > 0 ? "~\(gapH)h \(gapM)m" : "~\(gapM)m"
                    pool.append((6, "Her wakes were pretty evenly spaced (\(gapStr) apart). This rhythm is typical at \(weeks) weeks."))
                }
            }

            // Feed proximity to wake
            if let lastFeed = store.lastFeed {
                for wake in wakes {
                    let diff = abs(wake.timestamp.timeIntervalSince(lastFeed.timestamp))
                    if diff < 45 * 60 && diff > 10 * 60 {
                        pool.append((5, "She woke about \(Int(diff / 60))min after her last feed — could be discomfort rather than hunger. Try holding upright a bit longer after feeding."))
                        break
                    }
                }
            }

            // Default if nothing triggered
            if pool.isEmpty {
                let stretchStr = formatDuration(longest)
                pool.append((3, "Her longest stretch was \(stretchStr). At \(weeks) weeks, that's right on track."))
            }
        } else {
            // Day insights
            let feedCount = store.countToday([.bottle, .nursing, .pumping, .solids])
            let napMinutes = Int(store.totalSleepToday / 60)

            if feedCount >= 5 {
                pool.append((6, "\(feedCount) feeds today — she's eating well."))
            } else if feedCount <= 2 && feedCount > 0 {
                pool.append((7, "Only \(feedCount) feed\(feedCount == 1 ? "" : "s") logged so far. She might cluster later."))
            }

            if napMinutes >= 90 {
                pool.append((5, "Good nap day — \(napMinutes / 60)h \(napMinutes % 60)m of daytime sleep."))
            } else if napMinutes > 0 && napMinutes < 45 {
                pool.append((6, "Light on naps today. She might need a longer stretch soon — watch for those sleepy eyes."))
            }
        }

        // Sort by priority descending, take top 3
        return pool.sorted { $0.priority > $1.priority }.prefix(3).map(\.text)
    }

    private func generateActions() -> [String] {
        var pool: [(priority: Int, text: String)] = []

        if reportType == .sleep {
            let wakes = store.nightWakes(daysAgo: 0).sorted { $0.timestamp < $1.timestamp }
            let wakeCount = wakes.count

            // First wake before midnight
            if let first = wakes.first {
                let hour = Calendar.current.component(.hour, from: first.timestamp)
                if hour < 24 && hour >= 20 {
                    pool.append((8, "Try a dream feed around 10:30 PM — it can push that first wake later."))
                }
            }

            // Consistent wake times
            if wakeCount >= 2 {
                pool.append((5, "She's waking around the same times each night. A consistent bedtime routine 30min before can help."))
            }

            // Many wakes
            if wakeCount >= 3 {
                pool.append((7, "White noise and a dark room help newborns link sleep cycles. Worth trying if you haven't already."))
            }

            // Wake window hint
            if let sleepElapsed = store.timeSince([.nap, .wake]), sleepElapsed > 70 * 60 {
                let mins = Int(sleepElapsed / 60)
                pool.append((6, "Her last wake window yesterday was \(mins)min. Keeping it under 60min might help her settle faster tonight."))
            }
        } else {
            // Day action points
            if let napElapsed = store.timeSince([.nap, .wake]), napElapsed > 90 * 60 {
                pool.append((7, "She's been awake a while — if you see yawning or looking away, she's ready for a nap."))
            }

            if let feedElapsed = store.timeSince([.bottle, .nursing, .pumping, .solids]), feedElapsed > 2.5 * 3600 {
                pool.append((6, "It's been a while since her last feed — watch for hunger cues: rooting, lip smacking, hands to mouth."))
            }
        }

        return pool.sorted { $0.priority > $1.priority }.prefix(2).map(\.text)
    }

    // MARK: - Section 3: Recommended Reading

    @ViewBuilder
    private var readingSection: some View {
        let articles = SleepArticle.all.filter { ageWeeks >= $0.minWeeks && ageWeeks <= $0.maxWeeks }

        VStack(spacing: 10) {
            ForEach(articles.prefix(5)) { article in
                Button {
                    openURL(article.url)
                } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Source badge
                            Text(article.source)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.moonClay)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule()
                                        .fill(.moonCreme)
                                }

                            Text(article.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.moonObsidian)
                                .multilineTextAlignment(.leading)

                            Text(article.description)
                                .font(.system(size: 13))
                                .foregroundStyle(.moonOlive)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.moonClay)
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.moonWhite)
                            .shadow(color: .moonBlack.opacity(0.03), radius: 6, y: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
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

    private func formatTime(_ date: Date) -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d", h, minute)
    }

    private func ampm(_ date: Date) -> String {
        Calendar.current.component(.hour, from: date) >= 12 ? "PM" : "AM"
    }
}

// MARK: - Article Data

struct SleepArticle: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let description: String
    let url: URL
    let minWeeks: Int
    let maxWeeks: Int

    static let all: [SleepArticle] = [
        SleepArticle(
            title: "Safe Sleep for Babies",
            source: "AAP",
            description: "Back to sleep, firm surface, and room-sharing guidelines",
            url: URL(string: "https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/a-parents-guide-to-safe-sleep.aspx")!,
            minWeeks: 0,
            maxWeeks: 52
        ),
        SleepArticle(
            title: "How Much Sleep Do Newborns Need?",
            source: "Sleep Foundation",
            description: "Sleep totals by age and what's normal for your baby",
            url: URL(string: "https://www.sleepfoundation.org/baby-sleep/how-much-do-babies-sleep")!,
            minWeeks: 0,
            maxWeeks: 12
        ),
        SleepArticle(
            title: "Getting Your Baby to Sleep",
            source: "HealthyChildren.org",
            description: "Practical tips for establishing healthy sleep habits",
            url: URL(string: "https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/getting-your-baby-to-sleep.aspx")!,
            minWeeks: 0,
            maxWeeks: 24
        ),
        SleepArticle(
            title: "Helping Your Baby to Sleep",
            source: "NHS",
            description: "Bedtime routines and settling techniques that work",
            url: URL(string: "https://www.nhs.uk/conditions/baby/caring-for-a-newborn/helping-your-baby-to-sleep/")!,
            minWeeks: 0,
            maxWeeks: 24
        ),
        SleepArticle(
            title: "Infant Sleep",
            source: "Stanford Children's",
            description: "Understanding sleep cycles and patterns in the first year",
            url: URL(string: "https://www.stanfordchildrens.org/en/topic/default?id=infant-sleep-90-P02237")!,
            minWeeks: 0,
            maxWeeks: 52
        ),
        SleepArticle(
            title: "Sleep and Your Newborn",
            source: "Zero to Three",
            description: "What to expect in the first months and how to cope",
            url: URL(string: "https://www.zerotothree.org/resource/sleep-and-your-newborn/")!,
            minWeeks: 0,
            maxWeeks: 12
        ),
        SleepArticle(
            title: "Night Feeds and Breastfeeding",
            source: "La Leche League",
            description: "Why night feeds matter and when they naturally reduce",
            url: URL(string: "https://www.llli.org/breastfeeding-info/night-feedings/")!,
            minWeeks: 0,
            maxWeeks: 16
        ),
        SleepArticle(
            title: "The Science of Infant Sleep Patterns",
            source: "Parenting Science",
            description: "Research-backed insights into how baby sleep develops",
            url: URL(string: "https://parentingscience.com/baby-sleep-patterns/")!,
            minWeeks: 0,
            maxWeeks: 24
        ),
    ]
}
