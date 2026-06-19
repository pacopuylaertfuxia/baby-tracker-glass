import SwiftUI

/// Detail sheet for "Last night" — stat cards, vertical night timeline, insights.
struct LastNightDetail: View {
    @Environment(TimelineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

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
                Text("Last night")
                    .font(.kepler(32))
                    .foregroundStyle(.moonObsidian)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                if let report = store.lastNightReport {
                    // Stat cards
                    Spacer().frame(height: 24)
                    statCardsRow(report)

                    // Night timeline
                    Spacer().frame(height: 32)
                    sectionHeader("NIGHT TIMELINE")
                    Spacer().frame(height: 16)
                    nightTimeline(report)

                    // Insights
                    Spacer().frame(height: 32)
                    sectionHeader("INSIGHTS")
                    Spacer().frame(height: 12)
                    insightsSection(report)
                }

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

    // MARK: - Stat Cards

    private func statCardsRow(_ report: NightReport) -> some View {
        HStack(spacing: 12) {
            statCard(value: formatDuration(report.totalSleep), label: "Total sleep")
            statCard(value: "\(report.wakeCount)", label: "Wakes")
            statCard(value: formatDuration(report.longestStretch), label: "Longest stretch")
        }
        .padding(.horizontal, 16)
    }

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

    // MARK: - Vertical Night Timeline

    private func nightTimeline(_ report: NightReport) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(report.segments.enumerated()), id: \.element.id) { index, segment in
                timelineRow(
                    segment: segment,
                    isFirst: index == 0,
                    isLast: false
                )
            }

            // Good morning row
            goodMorningRow(report.wakeTime)
        }
        .padding(.horizontal, 24)
    }

    private func timelineRow(segment: NightSegment, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(spacing: 0) {
                Text(formatTime12(segment.start))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.moonOlive)
                    .monospacedDigit()
                Text(ampm(segment.start))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.moonClay)
            }
            .frame(width: 56, alignment: .trailing)

            // Dot + connector line
            VStack(spacing: 0) {
                Circle()
                    .fill(segment.isSleep ? Color.moonSleep : Color.clear)
                    .overlay {
                        if !segment.isSleep {
                            Circle()
                                .stroke(Color.moonClay, lineWidth: 2)
                        }
                    }
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(segment.isSleep ? Color.moonSleep : Color.moonClay.opacity(0.3))
                        .frame(width: segment.isSleep ? 2 : 1)
                        .frame(minHeight: 36)
                }
            }
            .frame(width: 10)

            // Label
            VStack(alignment: .leading, spacing: 2) {
                if segment.isSleep {
                    Text("\(formatDuration(segment.duration)) asleep")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.moonObsidian)
                } else {
                    Text(segment.reason ?? "\(formatDuration(segment.duration)) awake")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.moonClay)

                    Text(formatDuration(segment.duration))
                        .font(.system(size: 12))
                        .foregroundStyle(.moonStone)
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
    }

    private func goodMorningRow(_ wakeTime: Date) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(spacing: 0) {
                Text(formatTime12(wakeTime))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.moonOlive)
                    .monospacedDigit()
                Text(ampm(wakeTime))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.moonClay)
            }
            .frame(width: 56, alignment: .trailing)

            // Sun dot (no trailing line)
            Circle()
                .fill(Color.moonWake)
                .frame(width: 10, height: 10)
                .frame(width: 10)

            // Label
            HStack(spacing: 6) {
                Text("\u{2600}\u{FE0F}")
                    .font(.system(size: 14))
                Text("Good morning")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonObsidian)
            }

            Spacer()
        }
    }

    // MARK: - Insights

    private func insightsSection(_ report: NightReport) -> some View {
        let insights = buildInsights(report)

        return VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(insights.enumerated()), id: \.offset) { _, text in
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.moonClay)
                        .frame(width: 3, height: 36)

                    Text(text)
                        .font(.system(size: 14))
                        .foregroundStyle(.moonOlive)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func buildInsights(_ report: NightReport) -> [String] {
        var insights: [String] = []

        // Longest stretch
        if let seg = report.longestStretchSegment {
            insights.append(
                "Longest stretch was \(formatDuration(seg.duration)) (\(formatTime12(seg.start)) \(ampm(seg.start)) \u{2192} \(formatTime12(seg.end)) \(ampm(seg.end)))"
            )
        }

        // Trend vs previous night
        if let prev = store.previousNightReport {
            let diff = prev.wakeCount - report.wakeCount
            if diff > 0 {
                insights.append("\(diff) fewer wake\(diff == 1 ? "" : "s") than the night before")
            } else if diff < 0 {
                insights.append("\(abs(diff)) more wake\(abs(diff) == 1 ? "" : "s") than the night before")
            } else {
                insights.append("Same number of wakes as the night before")
            }
        }

        // Average wake duration
        if report.wakeCount > 0 {
            insights.append("Average wake lasted \(formatDuration(report.avgWakeDuration))")
        }

        return insights
    }

    // MARK: - Helpers

    private func formatTime12(_ date: Date) -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d", h12, minute)
    }

    private func ampm(_ date: Date) -> String {
        Calendar.current.component(.hour, from: date) >= 12 ? "PM" : "AM"
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        if m > 0 { return "\(m)m" }
        return "0m"
    }
}
