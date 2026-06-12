import SwiftUI

/// Single sleep ring with time slept stat
struct DailyRings: View {
    @Environment(TimelineStore.self) private var store

    private let sleepGoalHours: Double = 4

    var body: some View {
        HStack(spacing: 24) {
            // Ring
            ZStack {
                ring(progress: sleepProgress, color: .moonSleep, lineWidth: 18, radius: 44)

                // Center label
                VStack(spacing: 0) {
                    Image(systemName: "powersleep")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.moonSleep)
                }
            }
            .frame(width: 108, height: 108)

            // Sleep stat
            VStack(alignment: .leading, spacing: 4) {
                Text("Time napped")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.moonClay)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(formatSleep(store.totalSleepToday))
                    .font(.kepler(36))
                    .foregroundStyle(.moonObsidian)

                Text("of \(Int(sleepGoalHours))h goal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonClay)
            }

            Spacer()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.06), radius: 16, y: 6)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Ring

    private func ring(progress: Double, color: Color, lineWidth: CGFloat, radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)
                .shadow(color: color.opacity(0.4), radius: 6, y: 2)

            if progress > 0.05 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth + 2, height: lineWidth + 2)
                    .shadow(color: .white, radius: 1)
                    .shadow(color: color.opacity(0.6), radius: 4)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(360 * min(progress, 1.0) - 90))
                    .frame(width: radius * 2, height: radius * 2)
            }
        }
    }

    // MARK: - Helpers

    private var sleepProgress: Double {
        store.totalSleepToday / (sleepGoalHours * 3600)
    }

    private func formatSleep(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
