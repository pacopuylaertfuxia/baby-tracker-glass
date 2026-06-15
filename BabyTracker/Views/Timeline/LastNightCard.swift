import SwiftUI

/// Compact "Last night" card on the timeline home. Tap opens detail sheet.
struct LastNightCard: View {
    @Environment(TimelineStore.self) private var store
    @State private var showDetail = false

    var body: some View {
        if let report = store.lastNightReport {
            Button {
                showDetail = true
            } label: {
                cardContent(report)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .sheet(isPresented: $showDetail) {
                LastNightDetail()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.moonCreme)
            }
        }
    }

    // MARK: - Card Content

    private func cardContent(_ report: NightReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: moon + "Last night" + total sleep
            HStack {
                HStack(spacing: 8) {
                    Text("\u{1F319}")
                        .font(.system(size: 20))
                    Text("Last night")
                        .font(.keplerStat)
                        .foregroundStyle(.moonObsidian)
                }

                Spacer()

                Text(formatDuration(report.totalSleep))
                    .font(.keplerStat)
                    .foregroundStyle(.moonObsidian)
            }

            // Night bar
            nightBar(report)

            // Footer: bedtime / wake count / wake time
            HStack {
                Text(formatTime(report.bedtime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.moonClay)

                Spacer()

                Text("\(report.wakeCount) wake\(report.wakeCount == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.moonClay)

                Spacer()

                Text(formatTime(report.wakeTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.moonClay)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.06), radius: 16, y: 6)
        }
    }

    // MARK: - Night Bar

    private func nightBar(_ report: NightReport) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let total = report.totalNight

            HStack(spacing: 0) {
                if total > 0 {
                    ForEach(report.segments) { seg in
                        let fraction = seg.duration / total
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(seg.isSleep ? Color.moonSleep : Color.moonCreme)
                            .frame(width: max(2, CGFloat(fraction) * w - 1))
                    }
                }
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", h12, minute, period)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
