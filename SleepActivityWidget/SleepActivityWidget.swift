import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Design tokens (matches Moonboon production)

private enum Style {
    static let surfaceTertiary = Color(red: 0xE5/255, green: 0xD5/255, blue: 0xC5/255)
    static let surfaceSecondary = Color(red: 0xF1/255, green: 0xE8/255, blue: 0xDE/255)
    static let clay = Color(red: 0xB5/255, green: 0x9E/255, blue: 0x85/255)
    static let sleepBlue = Color(red: 74/255, green: 106/255, blue: 133/255)

    static func kepler(_ size: CGFloat) -> Font {
        .custom("KeplerStd-Disp", size: size)
    }
}

// MARK: - Widget

struct SleepActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepActivityAttributes.self) { context in
            LockScreenContent(context: context)
                .padding()
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    if context.attributes.sessionType == .motor {
                        MotorExpandedContent(context: context)
                    } else {
                        SleepExpandedContent(context: context)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.sessionType.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor(context.attributes.sessionType))
            } compactTrailing: {
                CompactTrailing(context: context)
            } minimal: {
                Image(systemName: context.attributes.sessionType.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor(context.attributes.sessionType))
            }
        }
    }
}

// MARK: - Compact Trailing (all types)

private struct CompactTrailing: View {
    let context: ActivityViewContext<SleepActivityAttributes>

    var body: some View {
        if context.attributes.sessionType == .motor, let target = context.state.targetDuration {
            // Motor: count-up toward target
            let start = context.state.startTime
            let end = start.addingTimeInterval(target)
            Text(timerInterval: start...end, countsDown: false, showsHours: target >= 3600)
                .monospacedDigit()
                .font(.system(size: 12, weight: .regular))
                .multilineTextAlignment(.trailing)
                .foregroundColor(Style.surfaceTertiary)
                .frame(width: target >= 3600 ? 50 : 36, alignment: .trailing)
        } else if context.state.isPaused {
            Text(formatInterval(context.state.pausedElapsed))
                .monospacedDigit()
                .font(.system(size: 12, weight: .regular))
                .multilineTextAlignment(.trailing)
                .foregroundColor(Style.surfaceTertiary)
                .frame(width: 36, alignment: .trailing)
        } else {
            Text(context.state.startTime, style: .timer)
                .monospacedDigit()
                .font(.system(size: 12, weight: .regular))
                .multilineTextAlignment(.trailing)
                .foregroundColor(Style.surfaceTertiary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

// MARK: - Expanded: Sleep (nap / bedtime)

private struct SleepExpandedContent: View {
    let context: ActivityViewContext<SleepActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: context.attributes.sessionType.icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor(context.attributes.sessionType))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text(context.attributes.babyName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Style.surfaceSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(context.state.isPaused ? "Paused" : context.attributes.sessionType.label)
                        .font(.system(size: 12))
                        .foregroundColor(Style.surfaceTertiary.opacity(0.7))

                    if context.attributes.sessionType == .bedtime && context.state.wakeCount > 0 {
                        Text("· \(context.state.wakeCount) wake\(context.state.wakeCount == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(Style.surfaceTertiary.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Kepler timer
            if context.state.isPaused {
                Text(formatInterval(context.state.pausedElapsed))
                    .font(Style.kepler(42))
                    .monospacedDigit()
                    .foregroundColor(Style.surfaceTertiary)
            } else {
                Text(context.state.startTime, style: .timer)
                    .font(Style.kepler(42))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Style.surfaceTertiary)
                    .frame(width: 92, alignment: .trailing)
                    .padding(.leading, -6)
            }
        }
    }
}

// MARK: - Expanded: Motor (countdown + progress bar — matches production)

private struct MotorExpandedContent: View {
    let context: ActivityViewContext<SleepActivityAttributes>

    private static let timerCellWidth: CGFloat = 48

    var body: some View {
        let state = context.state
        let start = state.startTime
        let target = state.targetDuration ?? (44 * 60)
        let end = start.addingTimeInterval(target)
        let useHours = target >= 3600

        VStack(spacing: 16) {
            // Top row: icon + name + Kepler countdown
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Style.clay)
                    .frame(width: 44, height: 44)

                Text(context.attributes.babyName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Style.surfaceSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(timerInterval: start...end, countsDown: true, showsHours: useHours)
                    .font(Style.kepler(42))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Style.surfaceTertiary)
                    .frame(width: useHours ? 130 : 92, alignment: .trailing)
                    .padding(.leading, -6)
            }

            // Bottom row: elapsed | progress bar | total
            HStack(spacing: 8) {
                Text(timerInterval: start...end, countsDown: false, showsHours: useHours)
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Style.surfaceTertiary)
                    .frame(width: Self.timerCellWidth, alignment: .trailing)

                ProgressView(timerInterval: start...end, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(Style.surfaceSecondary)
                .frame(height: 6)

                Text(formatStaticDuration(target, useHours: useHours))
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundColor(Style.surfaceTertiary)
            }
            .padding(.horizontal, 8)
        }
    }

    private func formatStaticDuration(_ seconds: TimeInterval, useHours: Bool) -> String {
        let total = max(0, Int(seconds))
        if useHours {
            let h = total / 3600
            let m = (total % 3600) / 60
            let s = total % 60
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Lock Screen

private struct LockScreenContent: View {
    let context: ActivityViewContext<SleepActivityAttributes>

    var body: some View {
        if context.attributes.sessionType == .motor {
            MotorExpandedContent(context: context)
        } else {
            SleepExpandedContent(context: context)
        }
    }
}

// MARK: - Shared helpers

private func iconColor(_ type: SleepActivityAttributes.SessionKind) -> Color {
    switch type {
    case .nap: Style.clay
    case .bedtime: Style.sleepBlue
    case .motor: Style.clay
    }
}

private func formatInterval(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%d:%02d", m, s)
}
