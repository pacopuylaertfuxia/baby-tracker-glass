import Foundation
import Combine
import UIKit

@MainActor
@Observable
final class SessionManager {
    var sessions: [ActiveSession] = []
    var currentTick: Date = .now

    private var timer: AnyCancellable?

    init() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.currentTick = date
            }
    }

    var hasActiveSessions: Bool { !sessions.isEmpty }
    var activeNap: ActiveSession? { sessions.first { $0.type == .nap } }
    var activeMonitor: ActiveSession? { sessions.first { $0.type == .monitor } }
    var activeMotor: ActiveSession? { sessions.first { $0.type == .motor } }

    func startNap() {
        guard activeNap == nil else { return }
        sessions.append(ActiveSession(type: .nap))
        haptic(.medium)
    }

    func startMonitor() {
        guard activeMonitor == nil else { return }
        sessions.append(ActiveSession(type: .monitor))
        haptic(.medium)
    }

    func startMotor() {
        guard activeMotor == nil else { return }
        sessions.append(ActiveSession(type: .motor, plannedDuration: 44 * 60))
        haptic(.medium)
    }

    func stopSession(_ session: ActiveSession) {
        sessions.removeAll { $0.id == session.id }
        haptic(.light)
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
