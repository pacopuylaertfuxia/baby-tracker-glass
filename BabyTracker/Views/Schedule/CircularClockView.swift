import SwiftUI

/// 24-hour circular clock rendered with Canvas for performance.
/// Midnight at top, clockwise. Shows sleep arcs, event dots, and "now" indicator.
struct CircularClockView: View {
    let events: [TimelineEvent]
    let currentTime: Date
    var onTapAngle: ((Date) -> Void)?

    // The track radius — labels sit outside, so frame must be larger
    private let trackRadius: CGFloat = 120
    private let trackWidth: CGFloat = 18
    private let dotRadius: CGFloat = 5
    private let labelOffset: CGFloat = 24
    // Total frame = trackRadius + labelOffset + text padding
    private var frameSize: CGFloat { (trackRadius + labelOffset + 16) * 2 }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // 1. Track ring
            drawTrackRing(context: context, center: center, radius: trackRadius)

            // 2. Night shading (6pm - 6am) — behind ticks
            drawNightShading(context: context, center: center, radius: trackRadius)

            // 3. Sleep arcs
            drawSleepArcs(context: context, center: center, radius: trackRadius)

            // 4. Event dots
            drawEventDots(context: context, center: center, radius: trackRadius)

            // 5. Hour ticks + labels — on top of arcs
            drawHourTicks(context: context, center: center, radius: trackRadius)

            // 6. "Now" indicator
            drawNowIndicator(context: context, center: center, radius: trackRadius)
        }
        .frame(width: frameSize, height: frameSize)
        .contentShape(Circle())
        .onTapGesture { location in
            let center = CGPoint(x: frameSize / 2, y: frameSize / 2)
            let angle = atan2(location.x - center.x, -(location.y - center.y))
            let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
            let tappedDate = angleToTime(normalizedAngle)
            onTapAngle?(tappedDate)
        }
    }

    // MARK: - Drawing

    private func drawTrackRing(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let trackPath = Path { p in
            p.addArc(center: center, radius: radius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
        }
        context.stroke(trackPath, with: .color(.moonClockTrack), style: StrokeStyle(lineWidth: trackWidth, lineCap: .round))
    }

    private func drawHourTicks(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        for hour in 0..<24 {
            let angle = hourToAngle(hour)
            let isMajor = hour % 6 == 0

            // Ticks: major extend outside + inside, minor are smaller
            let outerR = radius + (isMajor ? trackWidth / 2 + 2 : trackWidth / 2)
            let innerR = radius - (isMajor ? trackWidth / 2 + 2 : trackWidth / 2)

            let outerPoint = pointOnCircle(center: center, radius: outerR, angle: angle)
            let innerPoint = pointOnCircle(center: center, radius: innerR, angle: angle)

            var tickPath = Path()
            tickPath.move(to: outerPoint)
            tickPath.addLine(to: innerPoint)

            context.stroke(
                tickPath,
                with: .color(isMajor ? .moonOlive.opacity(0.5) : .moonStone.opacity(0.25)),
                style: StrokeStyle(lineWidth: isMajor ? 2 : 1, lineCap: .round)
            )

            // Labels for major hours — placed well outside the track
            if isMajor {
                let labelR = radius + labelOffset
                let labelPoint = pointOnCircle(center: center, radius: labelR, angle: angle)
                let label = hourLabel(hour)
                let text = Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.moonOlive)
                context.draw(context.resolve(text), at: labelPoint, anchor: .center)
            }
        }
    }

    private func drawNightShading(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Night = 6pm (hour 18) to 6am (hour 6)
        let startAngle = hourToAngle(18)
        let endAngle = hourToAngle(6)

        var nightPath = Path()
        nightPath.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

        context.stroke(nightPath, with: .color(.moonClockNight), style: StrokeStyle(lineWidth: trackWidth + 4, lineCap: .butt))
    }

    private func drawSleepArcs(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let sleepEvents = events.filter { $0.type == .nap || $0.type == .bedtime }

        for event in sleepEvents {
            guard let endTime = event.endTime else { continue }
            let startAngle = timeToAngle(event.timestamp)
            let endAngle = timeToAngle(endTime)

            var arcPath = Path()
            arcPath.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

            context.stroke(arcPath, with: .color(.moonSleep), style: StrokeStyle(lineWidth: trackWidth - 2, lineCap: .round))
        }
    }

    private func drawEventDots(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let dotTypes: Set<TimelineEvent.EventType> = [.bottle, .nursing, .solids, .diaper, .wake, .temperature, .medicine]

        for event in events where dotTypes.contains(event.type) {
            let angle = timeToAngle(event.timestamp)
            let point = pointOnCircle(center: center, radius: radius, angle: angle)

            // Soft halo
            let haloPath = Path(ellipseIn: CGRect(
                x: point.x - dotRadius - 2,
                y: point.y - dotRadius - 2,
                width: (dotRadius + 2) * 2,
                height: (dotRadius + 2) * 2
            ))
            context.fill(haloPath, with: .color(event.type.color.opacity(0.25)))

            // Solid dot
            let dotPath = Path(ellipseIn: CGRect(
                x: point.x - dotRadius,
                y: point.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(event.type.color))
        }
    }

    private func drawNowIndicator(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let angle = timeToAngle(currentTime)
        let point = pointOnCircle(center: center, radius: radius, angle: angle)

        // Outer glow
        let glowPath = Path(ellipseIn: CGRect(
            x: point.x - 10, y: point.y - 10, width: 20, height: 20
        ))
        context.fill(glowPath, with: .color(.moonClay.opacity(0.2)))

        // Mid ring
        let midPath = Path(ellipseIn: CGRect(
            x: point.x - 7, y: point.y - 7, width: 14, height: 14
        ))
        context.fill(midPath, with: .color(.moonClay.opacity(0.4)))

        // Inner dot
        let innerPath = Path(ellipseIn: CGRect(
            x: point.x - 4.5, y: point.y - 4.5, width: 9, height: 9
        ))
        context.fill(innerPath, with: .color(.moonClay))
    }

    // MARK: - Geometry Helpers

    /// Convert a Date to an angle on the 24h clock (midnight = top = 0, clockwise)
    func timeToAngle(_ date: Date) -> Angle {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let totalMinutes = Double(hour * 60 + minute)
        let fraction = totalMinutes / (24 * 60)
        return .degrees(fraction * 360)
    }

    /// Convert an angle (radians, 0 = top, clockwise) back to a Date (today)
    func angleToTime(_ radians: Double) -> Date {
        let fraction = radians / (2 * .pi)
        let totalMinutes = Int(fraction * 24 * 60)
        let hour = (totalMinutes / 60) % 24
        let minute = ((totalMinutes % 60) / 15) * 15 // snap to 15 min

        let cal = Calendar.current
        return cal.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }

    private func hourToAngle(_ hour: Int) -> Angle {
        .degrees(Double(hour) / 24.0 * 360)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        // Angle measured from top (12 o'clock), clockwise
        let radians = angle.radians - .pi / 2
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }

    private func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 6: return "6a"
        case 12: return "12p"
        case 18: return "6p"
        default: return "\(hour)"
        }
    }
}
