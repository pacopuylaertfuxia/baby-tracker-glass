import SwiftUI

/// Event card — icon, title, subtitle, time pill
struct TimelineEventRow: View {
    let event: TimelineEvent
    var isDashed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            if let imageName = event.type.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
            } else {
                Image(systemName: event.type.sfSymbol)
                    .font(.title3)
                    .foregroundStyle(.moonClay)
                    .frame(width: 36, height: 36)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.moonObsidian)
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.moonOlive)
                }
            }

            Spacer()

            // Time
            if !isDashed {
                HStack(spacing: 3) {
                    timePillView(event.timestamp)
                    if let end = event.endTime {
                        Text("–")
                            .font(.caption)
                            .foregroundStyle(.moonStone)
                        timePillView(end)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background {
            if isDashed {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.moonCardBg.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                            .foregroundStyle(.moonApricot)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.moonCardBg)
                    .shadow(color: .moonBlack.opacity(0.03), radius: 6, y: 2)
            }
        }
    }

    private func timePillView(_ date: Date) -> some View {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let ampm = hour >= 12 ? "pm" : "am"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)

        return HStack(spacing: 2) {
            Text(String(format: "%d:%02d", displayHour, minute))
                .font(.caption.weight(.medium))
                .monospacedDigit()
            Text(ampm)
                .font(.caption2)
                .opacity(0.6)
        }
        .foregroundStyle(.moonOlive)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.moonOverlay.opacity(0.06), in: Capsule())
    }
}
