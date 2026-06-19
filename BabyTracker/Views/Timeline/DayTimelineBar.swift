import SwiftUI

/// Day timeline — rounded capsule track with colored segments and a pulsing "now" indicator
struct DayTimelineBar: View {
    let segments: [TimelineSegment]

    var body: some View {
        VStack(spacing: 6) {
            // Bar
            GeometryReader { geo in
                let w = geo.size.width

                // Base track — subtle warm gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.moonApricot.opacity(0.2), .moonApricot.opacity(0.35)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .frame(maxHeight: .infinity, alignment: .center)

                // Segments
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    if seg.isCursor {
                        // "Now" indicator — small circle with glow
                        Circle()
                            .fill(.moonObsidian)
                            .frame(width: 8, height: 8)
                            .shadow(color: .moonObsidian.opacity(0.3), radius: 4)
                            .position(x: seg.startFraction * w, y: 6)
                    } else if seg.isDot {
                        Circle()
                            .fill(seg.color)
                            .frame(width: 6, height: 6)
                            .shadow(color: seg.color.opacity(0.4), radius: 3)
                            .position(x: seg.startFraction * w, y: 6)
                    } else {
                        let segWidth = max(6, (seg.endFraction - seg.startFraction) * w)
                        Capsule()
                            .fill(seg.color)
                            .frame(width: segWidth, height: 6)
                            .shadow(color: seg.color.opacity(0.3), radius: 2, y: 1)
                            .position(x: seg.startFraction * w + segWidth / 2, y: 6)
                    }
                }
            }
            .frame(height: 12)

            // Time labels — inline below the bar
            HStack {
                Text("6am")
                Spacer()
                Text("12pm")
                Spacer()
                Text("6pm")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.moonStone)
        }
        .padding(.horizontal, 24)
    }
}
