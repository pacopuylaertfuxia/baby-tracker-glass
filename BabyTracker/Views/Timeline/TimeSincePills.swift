import SwiftUI

/// Horizontally scrollable "time since" cards — icon floating out, time + "ago" below
struct TimeSinceRow: View {
    @Environment(TimelineStore.self) private var store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                timeSinceCard(
                    icon: "icon_feed",
                    label: "Last fed",
                    elapsed: store.timeSince([.bottle, .nursing, .pumping, .solids]),
                    rotation: 14,
                    iconOffset: CGSize(width: -28, height: -50)
                )
                timeSinceCard(
                    icon: "icon_nap",
                    label: "Last slept",
                    elapsed: store.timeSince([.nap]),
                    rotation: -12,
                    iconOffset: CGSize(width: -24, height: -48)
                )
                timeSinceCard(
                    icon: "icon_diaper",
                    label: "Last diaper",
                    elapsed: store.timeSince([.diaper]),
                    rotation: 16,
                    iconOffset: CGSize(width: -26, height: -52)
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
        rotation: Double,
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
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(rotation))
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
