import SwiftUI

/// Night wakes card with 3-day bar chart, tappable to show detail
struct NightWakesCard: View {
    @Environment(TimelineStore.self) private var store
    @State private var showDetail = false

    private var todayCount: Int { store.count([.nightWaking], daysAgo: 0) }
    private var yesterdayCount: Int { store.count([.nightWaking], daysAgo: 1) }
    private var dayBeforeCount: Int { store.count([.nightWaking], daysAgo: 2) }
    private var maxCount: Int { max(max(todayCount, yesterdayCount), max(dayBeforeCount, 1)) }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 20) {
                // Left — stat
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.moonSleep)
                        Text("Night wakes")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.moonClay)
                            .textCase(.uppercase)
                            .tracking(0.6)
                    }

                    Text("\(todayCount)")
                        .font(.kepler(42))
                        .foregroundStyle(.moonObsidian)

                    Text("last night")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.moonClay)
                }

                Spacer()

                // Right — 3-day bar chart
                HStack(alignment: .bottom, spacing: 10) {
                    barColumn(count: dayBeforeCount, label: dayLabel(daysAgo: 2))
                    barColumn(count: yesterdayCount, label: dayLabel(daysAgo: 1))
                    barColumn(count: todayCount, label: "Today", isToday: true)
                }
                .frame(height: 80)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.moonClay)
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.moonWhite)
                    .shadow(color: .moonBlack.opacity(0.06), radius: 16, y: 6)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .sheet(isPresented: $showDetail) {
            NightWakesDetail()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Bar Column

    private func barColumn(count: Int, label: String, isToday: Bool = false) -> some View {
        VStack(spacing: 6) {
            // Count label
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isToday ? .moonObsidian : .moonClay)

            // Bar
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isToday ? .moonSleep : .moonSleep.opacity(0.3))
                .frame(width: 28, height: barHeight(count))

            // Day label
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.moonClay)
        }
    }

    private func barHeight(_ count: Int) -> CGFloat {
        let maxHeight: CGFloat = 48
        let minHeight: CGFloat = 4
        guard maxCount > 0 else { return minHeight }
        return max(minHeight, CGFloat(count) / CGFloat(maxCount) * maxHeight)
    }

    private func dayLabel(daysAgo: Int) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: .now)!
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

// MARK: - Detail Sheet

struct NightWakesDetail: View {
    @Environment(TimelineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Night Wakes")
                    .font(.kepler(32))
                    .foregroundStyle(.moonObsidian)
                    .padding(.horizontal, 24)

                // Day sections
                daySection(title: "Last night", daysAgo: 0)
                daySection(title: "Yesterday", daysAgo: 1)
                daySection(title: dayTitle(daysAgo: 2), daysAgo: 2)

                Spacer(minLength: 30)
            }
            .padding(.top, 12)
        }
    }

    private func daySection(title: String, daysAgo: Int) -> some View {
        let wakes = store.nightWakes(daysAgo: daysAgo)
        let count = store.count([.nightWaking], daysAgo: daysAgo)

        return VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.moonClay)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text("\(count) wake\(count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonOlive)
            }
            .padding(.horizontal, 24)

            if wakes.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("No wakes — great night!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.moonOlive)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.moonWhite)
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(wakes) { wake in
                        wakeRow(wake)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func wakeRow(_ event: TimelineEvent) -> some View {
        HStack(spacing: 14) {
            // Time
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

            // Accent
            RoundedRectangle(cornerRadius: 2)
                .fill(.moonSleep)
                .frame(width: 3, height: 36)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Night waking")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.moonObsidian)
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.moonClay)
                }
            }

            Spacer()

            Image("icon_night_waking")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.03), radius: 6, y: 2)
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

    private func dayTitle(daysAgo: Int) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: .now)!
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }
}
