import SwiftUI

/// Overlay in the center of the circular clock showing prediction state:
/// countdown to next nap, active nap timer, or "nap window open" pulse.
struct PredictionCountdown: View {
    @Environment(TimelineStore.self) private var store
    @Environment(SessionManager.self) private var sessionManager
    @Environment(BabyStore.self) private var babyStore

    private enum PredictionState {
        case countdown(minutesLeft: Int)
        case windowOpen
        case activeNap(elapsed: TimeInterval)
        case bedtimeCountdown(minutesLeft: Int)
        case noData
    }

    private var state: PredictionState {
        // Active nap takes priority
        if let nap = sessionManager.activeNap {
            return .activeNap(elapsed: sessionManager.elapsed(for: nap))
        }

        // Calculate time since last wake/nap end
        let wakeWindow = babyStore.baby.wakeWindowMinutes
        if let timeSince = store.timeSince([.nap, .wake]) {
            let minutesSince = timeSince / 60
            let minutesLeft = Int(wakeWindow - minutesSince)

            if minutesLeft > 0 {
                return .countdown(minutesLeft: minutesLeft)
            } else {
                return .windowOpen
            }
        }

        return .noData
    }

    var body: some View {
        VStack(spacing: 4) {
            switch state {
            case .countdown(let minutesLeft):
                Text("Next nap in")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonOlive)

                Text("\(minutesLeft)")
                    .font(.keplerCountdown)
                    .foregroundStyle(.moonObsidian)
                    .contentTransition(.numericText())

                Text("min")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonClay)

            case .windowOpen:
                Text("Nap window")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonClay)

                Text("OPEN")
                    .font(.keplerCountdown)
                    .foregroundStyle(.moonSleep)
                    .opacity(pulseOpacity)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseOpacity)

            case .activeNap(let elapsed):
                Text("Napping")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonSleep)

                Text(formatDuration(elapsed))
                    .font(.keplerCountdown)
                    .monospacedDigit()
                    .foregroundStyle(.moonObsidian)
                    .contentTransition(.numericText())

            case .bedtimeCountdown(let minutesLeft):
                Text("Bedtime in")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonOlive)

                Text("\(minutesLeft)")
                    .font(.keplerCountdown)
                    .foregroundStyle(.moonObsidian)

                Text("min")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonClay)

            case .noData:
                Text("Track sleep")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonOlive)

                Text("to predict")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonOlive)
            }
        }
        .frame(width: 140, height: 100)
    }

    @State private var pulseOpacity: Double = 1.0

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
