import SwiftUI

/// Two pill-shaped stat chips side by side. Progress shown as border stroke progressing around the pill.
struct DailyStatsBar: View {
    @Environment(TimelineStore.self) private var store
    @State private var showDetail = false

    private let sleepGoal: TimeInterval = 4 * 3600
    private let napGoal: Double = 3

    var body: some View {
        HStack(spacing: 10) {
            Button { showDetail = true } label: {
                statPill(
                    icon: "clock.fill",
                    tint: .moonSleep,
                    value: formatSleep(store.totalSleepToday),
                    label: "slept",
                    progress: store.totalSleepToday / sleepGoal
                )
            }
            .buttonStyle(.plain)

            Button { showDetail = true } label: {
                statPill(
                    icon: "moon.fill",
                    tint: .moonClay,
                    value: "\(store.napCountToday)",
                    label: store.napCountToday == 1 ? "nap" : "naps",
                    progress: Double(store.napCountToday) / napGoal
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .fullScreenCover(isPresented: $showDetail) {
            DailyStatsDetail()
        }
    }

    // MARK: - Pill

    private func statPill(icon: String, tint: Color, value: String, label: String, progress: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.kepler(22))
                .foregroundStyle(.moonObsidian)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.6), value: value)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.moonOlive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            ProgressBorderPill(progress: min(progress, 1.0), tint: tint)
        }
    }

    private func formatSleep(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}

// MARK: - Progress Border Pill

/// Pill-shaped container where the border stroke traces around the perimeter to show progress.
private struct ProgressBorderPill: View {
    let progress: Double
    let tint: Color

    private let trackWidth: CGFloat = 2.5

    var body: some View {
        ZStack {
            Capsule()
                .fill(.moonWhite)

            Capsule()
                .strokeBorder(tint.opacity(0.12), lineWidth: trackWidth)

            PillPerimeterShape()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                )
                .padding(trackWidth / 2)
                .animation(.spring(duration: 0.8, bounce: 0.12), value: progress)
        }
        .shadow(color: .moonBlack.opacity(0.04), radius: 6, y: 3)
    }
}

/// A shape that traces the pill (stadium) perimeter starting from top-center, going clockwise.
private struct PillPerimeterShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.height / 2
        let midX = rect.midX

        var path = Path()

        // Start top center
        path.move(to: CGPoint(x: midX, y: 0))

        // Top edge → right
        path.addLine(to: CGPoint(x: rect.maxX - r, y: 0))

        // Right semicircle (clockwise)
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: r),
            radius: r,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge → left
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))

        // Left semicircle (clockwise)
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: r),
            radius: r,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Top edge back to start
        path.addLine(to: CGPoint(x: midX, y: 0))

        return path
    }
}

// MARK: - Full-Screen Detail

private struct DailyStatsDetail: View {
    @Environment(TimelineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let sleepGoal: TimeInterval = 4 * 3600
    private let napGoal: Double = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // ── Sleep ──
                    sectionHeader("Sleep", icon: "powersleep", tint: .moonSleep)

                    HStack(spacing: 12) {
                        detailCard(
                            tint: .moonSleep,
                            value: formatSleep(store.totalSleepToday),
                            label: "Total napped",
                            progress: store.totalSleepToday / sleepGoal
                        )
                        detailCard(
                            tint: .moonSleep,
                            value: "\(store.napCountToday)",
                            label: "Naps today",
                            progress: Double(store.napCountToday) / napGoal
                        )
                    }

                    if let report = store.lastNightReport {
                        HStack(spacing: 12) {
                            detailCard(
                                tint: .moonSleep,
                                value: formatSleep(report.totalSleep),
                                label: "Last night",
                                progress: nil
                            )
                            detailCard(
                                tint: .moonWake,
                                value: "\(report.wakeCount)",
                                label: "Night wakes",
                                progress: nil
                            )
                        }
                    }

                    // ── Feeding ──
                    let feedCount = store.countToday([.bottle, .nursing, .pumping, .solids])
                    let bottleCount = store.countToday([.bottle])
                    let nursingCount = store.countToday([.nursing])

                    sectionHeader("Feeding", icon: "fork.knife", tint: .moonFood)

                    HStack(spacing: 12) {
                        detailCard(
                            tint: .moonFood,
                            value: "\(feedCount)",
                            label: "Total feeds",
                            progress: nil
                        )
                        if nursingCount > 0 {
                            detailCard(
                                tint: .moonFood,
                                value: "\(nursingCount)",
                                label: "Nursing",
                                progress: nil
                            )
                        } else {
                            detailCard(
                                tint: .moonFood,
                                value: "\(bottleCount)",
                                label: "Bottles",
                                progress: nil
                            )
                        }
                    }

                    // ── Care ──
                    let diaperCount = store.countToday([.diaper])

                    sectionHeader("Care", icon: "sparkles", tint: .moonChange)

                    HStack(spacing: 12) {
                        detailCard(
                            tint: .moonChange,
                            value: "\(diaperCount)",
                            label: "Diaper changes",
                            progress: nil
                        )
                        Color.clear
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(.moonCreme)
            .navigationTitle("Today's summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.moonClay)
                    }
                }
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.moonClay)
                .textCase(.uppercase)
                .tracking(0.6)
            Spacer()
        }
        .padding(.top, 12)
    }

    private func detailCard(tint: Color, value: String, label: String, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value)
                .font(.kepler(36))
                .foregroundStyle(.moonObsidian)
                .contentTransition(.numericText())

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.moonOlive)

            if let progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(tint.opacity(0.10))
                        Capsule()
                            .fill(tint)
                            .frame(width: max(4, geo.size.width * min(progress, 1.0)))
                    }
                }
                .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.06), radius: 16, y: 6)
        }
    }

    private func formatSleep(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
