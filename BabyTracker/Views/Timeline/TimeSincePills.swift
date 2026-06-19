import SwiftUI

/// Single "awake for" indicator — the one metric parents can act on
struct TimeSinceRow: View {
    @Environment(TimelineStore.self) private var store

    var body: some View {
        if let elapsed = store.timeSince([.nap, .wake]) {
            HStack(spacing: 12) {
                Image("icon_nap")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Awake for")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.moonClay)
                        .textCase(.uppercase)
                        .tracking(0.4)

                    Text(formatElapsed(elapsed))
                        .font(.kepler(28))
                        .foregroundStyle(.moonObsidian)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Spacer()

                // Gentle cue when wake window is long
                if elapsed > 2 * 3600 {
                    Text("Watch for sleepy cues")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.moonClay)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(.moonCreme)
                        }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.moonCreme)
                    .shadow(color: .moonBlack.opacity(0.05), radius: 12, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
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
