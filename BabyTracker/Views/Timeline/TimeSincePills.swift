import SwiftUI

/// Horizontally scrollable "time since" cards — big icon floating top-left, time + "ago" below
struct TimeSinceRow: View {
    @Environment(TimelineStore.self) private var store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                timeSinceCard(
                    icon: "icon_feed",
                    label: "Last fed",
                    elapsed: store.timeSince([.bottle, .nursing, .pumping, .solids]),
                    iconOffset: CGSize(width: -10, height: -40)
                )
                timeSinceCard(
                    icon: "icon_nap",
                    label: "Last slept",
                    elapsed: store.timeSince([.nap]),
                    iconOffset: CGSize(width: -6, height: -38)
                )
                timeSinceCard(
                    icon: "icon_diaper",
                    label: "Last diaper",
                    elapsed: store.timeSince([.diaper]),
                    iconOffset: CGSize(width: -8, height: -42)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)
        }
    }

    private func timeSinceCard(
        icon: String,
        label: String,
        elapsed: TimeInterval?,
        iconOffset: CGSize
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()

            // Label
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.moonClay)
                .textCase(.uppercase)
                .tracking(0.4)

            // Time
            Text(elapsed.map { formatElapsed($0) } ?? "—")
                .font(.kepler(34))
                .foregroundStyle(.moonObsidian)
                .monospacedDigit()
                .contentTransition(.numericText())

            // Ago
            Text("ago")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.moonClay)
        }
        .frame(width: 130, height: 150, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.moonCreme)
                .shadow(color: .moonBlack.opacity(0.05), radius: 12, y: 4)
        }
        .overlay(alignment: .topLeading) {
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 110, height: 110)
                .offset(iconOffset)
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
