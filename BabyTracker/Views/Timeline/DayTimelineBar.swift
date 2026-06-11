import SwiftUI

/// Multi-color horizontal timeline bar (6am–10pm) from the Figma vision
struct DayTimelineBar: View {
    let segments: [TimelineSegment]
    let timeLabels = ["6am", "8am", "10am", "12pm", "2pm", "4pm"]

    var body: some View {
        VStack(spacing: 6) {
            // Time labels
            HStack {
                ForEach(timeLabels, id: \.self) { label in
                    Text(label)
                        .font(.footnote)
                        .foregroundStyle(.moonOlive)
                    if label != timeLabels.last {
                        Spacer()
                    }
                }
            }

            // The bar
            GeometryReader { geo in
                let w = geo.size.width

                // Base track
                RoundedRectangle(cornerRadius: 4)
                    .fill(.moonApricot.opacity(0.5))
                    .frame(height: 8)

                // Awake fill (gold) — full width behind sleep segments
                RoundedRectangle(cornerRadius: 4)
                    .fill(.moonWake)
                    .frame(height: 8)

                // Segments overlay
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    if seg.isCursor {
                        // Current time cursor — vertical line with dot
                        VStack(spacing: 0) {
                            Circle()
                                .fill(.moonBlack)
                                .frame(width: 6, height: 6)
                            Rectangle()
                                .fill(.moonBlack)
                                .frame(width: 1.5, height: 20)
                        }
                        .position(x: seg.startFraction * w, y: 4)
                    } else if seg.isDot {
                        // Point event — small colored dot on the bar
                        Circle()
                            .fill(seg.color)
                            .frame(width: 8, height: 8)
                            .position(x: seg.startFraction * w, y: 4)
                    } else {
                        // Duration segment (e.g. sleep)
                        let segWidth = max(4, (seg.endFraction - seg.startFraction) * w)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(seg.color)
                            .frame(width: segWidth, height: 8)
                            .position(x: seg.startFraction * w + segWidth / 2, y: 4)
                    }
                }
            }
            .frame(height: 26)

            // Legend chips
            HStack(spacing: 4) {
                legendChip("Wake", color: .moonWake)
                legendChip("Sleep", color: .moonSleep)
                legendChip("Food", color: .moonFood)
                legendChip("Change", color: .moonChange)
                Spacer()
            }
        }
        .padding(.horizontal, 24)
    }

    private func legendChip(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.moonOlive)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.moonCreme.opacity(0.9), in: Capsule())
    }
}
