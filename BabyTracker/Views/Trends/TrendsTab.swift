import SwiftUI

/// Trends tab — reuses WeeklyChart and NightWakesCard with sleep trend indicator.
struct TrendsTab: View {
    @Environment(TimelineStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sleep trend indicator
                sleepTrendBanner

                // Weekly chart
                WeeklyChart()

                // Night wakes card
                NightWakesCard()

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("Trends")
    }

    private var sleepTrendBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: trendIcon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(trendColor)
                .frame(width: 40, height: 40)
                .background(trendColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep trend")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.moonClay)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(trendLabel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.moonObsidian)
            }

            Spacer()
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.04), radius: 10, y: 4)
        }
        .padding(.horizontal, 16)
    }

    private var trendIcon: String {
        switch store.sleepTrend {
        case .improving: return "arrow.up.right"
        case .same: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    private var trendColor: Color {
        switch store.sleepTrend {
        case .improving: return .moonSuccess
        case .same: return .moonClay
        case .declining: return .moonError
        }
    }

    private var trendLabel: String {
        switch store.sleepTrend {
        case .improving: return "Improving — longer stretches"
        case .same: return "Consistent — steady pattern"
        case .declining: return "Shorter stretches lately"
        }
    }
}
