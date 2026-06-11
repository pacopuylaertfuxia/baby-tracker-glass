import SwiftUI

/// Frosted glass event card — 3D icon from Figma, event title, time pills
struct TimelineEventRow: View {
    let event: TimelineEvent
    var isDashed: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon from asset catalog (fallback to SF Symbol)
            if let imageName = event.type.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: event.type.sfSymbol)
                    .font(.title2)
                    .foregroundStyle(.moonClay)
                    .frame(width: 40, height: 40)
            }

            // Event name
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body.weight(.medium))  // 17pt — Apple HIG body
                    .foregroundStyle(.moonObsidian)
                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.subheadline)  // 15pt
                        .foregroundStyle(.moonOlive)
                }
            }

            Spacer()

            // Time pill(s)
            HStack(spacing: 4) {
                timePillView(event.timestamp)

                if let end = event.endTime {
                    Text("–")
                        .font(.subheadline)
                        .foregroundStyle(.moonStone)
                    timePillView(end)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            if isDashed {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(.moonApricot)
                    )
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.moonCreme, lineWidth: 0.5)
                    )
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
                .font(.subheadline.weight(.medium))  // 15pt
                .monospacedDigit()
            Text(ampm)
                .font(.footnote)  // 13pt
                .opacity(0.7)
        }
        .foregroundStyle(.moonOlive)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white, in: Capsule())
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}
