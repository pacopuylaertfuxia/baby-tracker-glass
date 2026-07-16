import SwiftUI

// Utility — shared time formatting
func formatDuration(_ interval: TimeInterval) -> String {
    let total = Int(max(0, interval))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
}

/// Unified full-screen sleep tracker for both naps and bedtime.
/// Same dark UI, same layout — mode determines icon, buttons, and behavior.
struct SleepTrackingScreen: View {
    enum Mode { case nap, bedtime }

    let mode: Mode
    /// When true (bedtime mode), the screen opens directly in the Awake state —
    /// used when tracking a Night waking from the home screen.
    var startAwake: Bool = false

    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(BabyStore.self) private var babyStore
    @Environment(\.dismiss) private var dismiss

    // Shared
    @State private var isPaused = false
    @State private var pausedElapsed: TimeInterval = 0

    // Bedtime-only
    @State private var isAwake = false
    @State private var noteText = ""
    @State private var selectedReason: String?
    @State private var voiceRecorder = VoiceMemoRecorder()
    @State private var wakeStartTime: Date?

    private static let darkBg = Color(red: 0.06, green: 0.05, blue: 0.04)
    private static let reasons = ["Hungry", "Fussy", "Diaper", "Comfort"]

    private var session: ActiveSession? {
        mode == .nap ? sessionManager.activeNap : sessionManager.activeBedtime
    }

    private var elapsed: TimeInterval {
        if isPaused { return pausedElapsed }
        guard let session else { return 0 }
        return sessionManager.elapsed(for: session)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Self.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if mode == .bedtime && isAwake {
                    awakeView
                        .transition(.opacity)
                } else {
                    sleepingView
                        .transition(.opacity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if mode == .bedtime {
                UIApplication.shared.isIdleTimerDisabled = true
                if startAwake && wakeStartTime == nil {
                    wakeStartTime = .now
                    isAwake = true
                }
            }
        }
        .onDisappear {
            if mode == .bedtime {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }

    // MARK: - Top Bar (shared)

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.1), in: Circle())
            }

            Spacer()

            if let session {
                Text("Started \(session.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Sleeping State (shared layout)

    private var sleepingView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Group {
                switch mode {
                case .nap:
                    Text("\u{1F4A4}")
                        .font(.system(size: 36))
                case .bedtime:
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.moonSleep)
                }
            }
            .padding(.bottom, 8)

            // Label
            Text(sleepingLabel)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 32)

            // Timer
            Text(formatDuration(elapsed))
                .font(.kepler(56))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.white)
                .padding(.bottom, 6)

            // Since
            if let session {
                Text("since \(session.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 48)
            }

            // Buttons
            sleepingButtons

            // Tonight's night wakings (bedtime only)
            if mode == .bedtime && !tonightWakes.isEmpty {
                VStack(spacing: 8) {
                    Text("\(tonightWakes.count) wake-up\(tonightWakes.count == 1 ? "" : "s") tonight")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))

                    ForEach(tonightWakes) { wake in
                        nightWakeRow(wake)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            Spacer()
        }
    }

    /// Night waking events logged since this bedtime session started.
    private var tonightWakes: [TimelineEvent] {
        guard let bedtime = sessionManager.activeBedtime else { return [] }
        return timelineStore.events
            .filter { $0.type == .nightWaking && $0.timestamp >= bedtime.startTime }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func nightWakeRow(_ wake: TimelineEvent) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 14))
                .foregroundStyle(.moonSleep)

            VStack(alignment: .leading, spacing: 1) {
                Text("Night waking")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                if let subtitle = wake.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Text(Self.awakeWindowText(for: wake))
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    /// "1:30 – 1:38 AM" when we know how long baby was awake, otherwise the wake time.
    static func awakeWindowText(for event: TimelineEvent) -> String {
        let start = event.timestamp.formatted(date: .omitted, time: .shortened)
        guard let duration = event.wakeDuration, duration > 0 else { return start }
        let end = event.timestamp.addingTimeInterval(duration)
            .formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    private var sleepingLabel: String {
        switch mode {
        case .nap: isPaused ? "Paused" : "Napping"
        case .bedtime: "Sleeping"
        }
    }

    @ViewBuilder
    private var sleepingButtons: some View {
        switch mode {
        case .nap:
            // Save + Pause
            VStack(spacing: 16) {
                Button { saveNap() } label: {
                    Text("Save nap")
                        .font(.kepler(28))
                        .foregroundStyle(.moonBlack)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                .background(.moonClay, in: Capsule())

                Button { togglePause() } label: {
                    Text(isPaused ? "Resume" : "Pause")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .background(.white.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 24)

        case .bedtime:
            // Woke up + Good morning
            VStack(spacing: 16) {
                Button {
                    wakeStartTime = Date.now
                    withAnimation(.easeInOut(duration: 0.35)) { isAwake = true }
                } label: {
                    Text("\(babyStore.baby.name) woke up")
                        .font(.kepler(28))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                .background(.moonSleep, in: Capsule())

                Button { endNight() } label: {
                    Text("Good morning, \(babyStore.baby.name)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .background(.moonWake, in: Capsule())
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Awake State (bedtime only)

    private var awakeView: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Awake \u{00B7} \(Date.now.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.bottom, 32)

            Button { logWakeAndSleep() } label: {
                Text("Back to sleep")
                    .font(.kepler(28))
                    .foregroundStyle(.moonBlack)
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
            .background(.moonClay, in: Capsule())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Quick reason pills
            HStack(spacing: 10) {
                ForEach(Self.reasons, id: \.self) { reason in
                    Button {
                        selectedReason = selectedReason == reason ? nil : reason
                    } label: {
                        Text(reason)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selectedReason == reason ? .moonBlack : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedReason == reason ? Color.moonClay : Color.white.opacity(0.12),
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.bottom, 20)

            // Note input + mic
            HStack(spacing: 12) {
                TextField("Add a note...", text: $noteText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.08), in: Capsule())

                Button {
                    if voiceRecorder.isRecording {
                        voiceRecorder.stopRecording()
                    } else {
                        voiceRecorder.startRecording()
                    }
                } label: {
                    Image(systemName: voiceRecorder.isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(voiceRecorder.isRecording ? .red : .white.opacity(0.6))
                        .frame(width: 48, height: 48)
                        .background(
                            voiceRecorder.isRecording ? Color.red.opacity(0.15) : Color.white.opacity(0.08),
                            in: Circle()
                        )
                        .overlay {
                            if voiceRecorder.isRecording {
                                Circle()
                                    .stroke(.red.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.2)
                                    .opacity(voiceRecorder.isRecording ? 0.6 : 0)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: voiceRecorder.isRecording)
                            }
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            // Voice memo preview
            if voiceRecorder.recordingURL != nil && !voiceRecorder.isRecording {
                HStack(spacing: 12) {
                    Button {
                        if voiceRecorder.isPlaying {
                            voiceRecorder.stopPlayback()
                        } else {
                            voiceRecorder.playback()
                        }
                    } label: {
                        Image(systemName: voiceRecorder.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.3))
                        .frame(height: 4)

                    Text(formatDuration(voiceRecorder.duration))
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))

                    Button {
                        voiceRecorder.deleteRecording()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func saveNap() {
        guard let session else { return }
        let duration = isPaused ? pausedElapsed : sessionManager.elapsed(for: session)
        sessionManager.stopSession(session)
        timelineStore.logNap(duration: duration)
        dismiss()
    }

    private func togglePause() {
        if isPaused {
            isPaused = false
            sessionManager.updateNapPauseState(isPaused: false, pausedElapsed: 0)
        } else {
            guard let session else { return }
            pausedElapsed = sessionManager.elapsed(for: session)
            isPaused = true
            sessionManager.updateNapPauseState(isPaused: true, pausedElapsed: pausedElapsed)
        }
    }

    private func logWakeAndSleep() {
        var parts: [String] = []
        if let reason = selectedReason { parts.append(reason) }
        if !noteText.isEmpty { parts.append(noteText) }
        let subtitle = parts.isEmpty ? nil : parts.joined(separator: " — ")

        let wakeStart = wakeStartTime ?? .now
        let wakeDur = Date.now.timeIntervalSince(wakeStart)

        timelineStore.logNightWake(
            subtitle: subtitle,
            timestamp: wakeStart,
            audioURL: voiceRecorder.recordingURL,
            wakeDuration: wakeDur
        )

        noteText = ""
        selectedReason = nil
        wakeStartTime = nil
        voiceRecorder.deleteRecording()

        sessionManager.updateBedtimeWakeCount()

        withAnimation(.easeInOut(duration: 0.35)) { isAwake = false }
    }

    private func endNight() {
        timelineStore.logEvent(.wake)
        sessionManager.stopBedtime()
        dismiss()
    }
}
