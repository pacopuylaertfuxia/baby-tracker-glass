@preconcurrency import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var activityId: String?

    func start(
        babyName: String,
        sessionType: SleepActivityAttributes.SessionKind,
        startTime: Date,
        targetDuration: TimeInterval? = nil
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = SleepActivityAttributes(
            babyName: babyName,
            sessionType: sessionType
        )
        let state = SleepActivityAttributes.ContentState(
            startTime: startTime,
            isPaused: false,
            pausedElapsed: 0,
            wakeCount: 0,
            targetDuration: targetDuration
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            activityId = activity.id
        } catch {
            print("Live Activity start failed: \(error)")
        }
    }

    func update(
        startTime: Date,
        isPaused: Bool,
        pausedElapsed: TimeInterval,
        wakeCount: Int,
        targetDuration: TimeInterval? = nil
    ) async {
        guard let activityId else { return }
        guard let activity = Activity<SleepActivityAttributes>.activities.first(where: { $0.id == activityId }) else { return }

        let state = SleepActivityAttributes.ContentState(
            startTime: startTime,
            isPaused: isPaused,
            pausedElapsed: pausedElapsed,
            wakeCount: wakeCount,
            targetDuration: targetDuration
        )

        await activity.update(.init(state: state, staleDate: nil))
    }

    func end() async {
        guard let activityId else { return }
        self.activityId = nil

        guard let activity = Activity<SleepActivityAttributes>.activities.first(where: { $0.id == activityId }) else { return }

        let finalState = SleepActivityAttributes.ContentState(
            startTime: .now,
            isPaused: true,
            pausedElapsed: 0,
            wakeCount: 0,
            targetDuration: nil
        )
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
    }

    func endAll() async {
        activityId = nil
        for activity in Activity<SleepActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
