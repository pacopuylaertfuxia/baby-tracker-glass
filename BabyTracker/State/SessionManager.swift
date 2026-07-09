import Foundation
import Combine
import UIKit

@MainActor
@Observable
final class SessionManager {
    var sessions: [ActiveSession] = []
    var currentTick: Date = .now
    var babyName: String = "Baby"

    private var timer: AnyCancellable?
    private let liveActivity = LiveActivityManager()

    // Nap pause state (tracked here so Live Activity can be updated)
    private(set) var napIsPaused = false
    private(set) var napPausedElapsed: TimeInterval = 0

    // Bedtime wake count (tracked here so Live Activity can be updated)
    private(set) var bedtimeWakeCount = 0

    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.currentTick = date
            }
        Task { await liveActivity.endAll() }
    }

    var hasActiveSessions: Bool { !sessions.isEmpty }
    var activeNap: ActiveSession? { sessions.first { $0.type == .nap } }
    var activeMonitor: ActiveSession? { sessions.first { $0.type == .monitor } }
    var activeMotor: ActiveSession? { sessions.first { $0.type == .motor } }
    var activeBedtime: ActiveSession? { sessions.first { $0.type == .bedtime } }

    func startNap() {
        guard activeNap == nil else { return }
        let session = ActiveSession(type: .nap)
        sessions.append(session)
        napIsPaused = false
        napPausedElapsed = 0
        haptic(.medium)

        liveActivity.start(
            babyName: babyName,
            sessionType: .nap,
            startTime: session.startTime
        )
    }

    func startMonitor() {
        guard activeMonitor == nil else { return }
        sessions.append(ActiveSession(type: .monitor))
        haptic(.medium)
    }

    func startMotor() {
        guard activeMotor == nil else { return }
        let duration: TimeInterval = 44 * 60
        let session = ActiveSession(type: .motor, plannedDuration: duration)
        sessions.append(session)
        haptic(.medium)

        liveActivity.start(
            babyName: babyName,
            sessionType: .motor,
            startTime: session.startTime,
            targetDuration: duration
        )
    }

    func stopSession(_ session: ActiveSession) {
        sessions.removeAll { $0.id == session.id }
        haptic(.light)

        if session.type == .nap || session.type == .bedtime || session.type == .motor {
            Task { await liveActivity.end() }
        }

        if session.type == .nap {
            napIsPaused = false
            napPausedElapsed = 0
        }
        if session.type == .bedtime {
            bedtimeWakeCount = 0
        }
    }

    func stopNap() {
        if let nap = activeNap { stopSession(nap) }
    }

    func stopMonitor() {
        if let monitor = activeMonitor { stopSession(monitor) }
    }

    func stopMotor() {
        if let motor = activeMotor { stopSession(motor) }
    }

    func startBedtime() {
        guard activeBedtime == nil else { return }
        let session = ActiveSession(type: .bedtime)
        sessions.append(session)
        bedtimeWakeCount = 0
        haptic(.medium)

        liveActivity.start(
            babyName: babyName,
            sessionType: .bedtime,
            startTime: session.startTime
        )
    }

    func stopBedtime() {
        if let bedtime = activeBedtime { stopSession(bedtime) }
    }

    // MARK: - Live Activity Updates

    func updateNapPauseState(isPaused: Bool, pausedElapsed: TimeInterval) {
        napIsPaused = isPaused
        napPausedElapsed = pausedElapsed

        guard let nap = activeNap else { return }
        Task {
            await liveActivity.update(
                startTime: nap.startTime,
                isPaused: isPaused,
                pausedElapsed: pausedElapsed,
                wakeCount: 0
            )
        }
    }

    func updateBedtimeWakeCount() {
        bedtimeWakeCount += 1

        guard let bedtime = activeBedtime else { return }
        Task {
            await liveActivity.update(
                startTime: bedtime.startTime,
                isPaused: false,
                pausedElapsed: 0,
                wakeCount: bedtimeWakeCount
            )
        }
    }

    // MARK: - Helpers

    func elapsed(for session: ActiveSession) -> TimeInterval {
        currentTick.timeIntervalSince(session.startTime)
    }

    func remaining(for session: ActiveSession) -> TimeInterval? {
        guard let planned = session.plannedDuration else { return nil }
        return max(0, planned - elapsed(for: session))
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
