import SwiftUI

/// Apple Music "Now Playing" style session bar.
/// Full-width glass bar above the tab bar. Tap to expand.
struct SessionAccessoryContent: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @State private var showSheet = false

    var body: some View {
        collapsedBar
            .onTapGesture {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                expandedSheet
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
            }
    }

    // MARK: - Collapsed: adaptive pill layout (1 / 2 / 3 sessions)

    private var collapsedBar: some View {
        let sessions = sessionManager.sessions
        return HStack(spacing: 8) {
            switch sessions.count {
            case 1:
                if let s = sessions.first {
                    sessionPill(s, compact: false)
                }
            case 2:
                ForEach(sessions) { s in
                    sessionPill(s, compact: false)
                }
            default:
                ForEach(sessions) { s in
                    sessionPill(s, compact: true)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
    }

    /// Single glass pill for a session.
    /// `compact`: when true, shows icon + timer only (3-session mode).
    private func sessionPill(_ session: ActiveSession, compact: Bool) -> some View {
        HStack(spacing: 8) {
            sessionIcon(session)
                .frame(width: 36, height: 36)

            if compact {
                // Timer only
                timerLabel(session)
            } else {
                // Label + timer stacked
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.type.sessionLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.moonObsidian)
                        .lineLimit(1)
                    timerLabel(session)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func sessionIcon(_ session: ActiveSession) -> some View {
        switch session.type {
        case .nap:
            Image("icon_nap")
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .motor:
            Image("icon_moon")
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .monitor:
            Image(systemName: "video.fill")
                .font(.body)
                .foregroundStyle(.moonClay)
        }
    }

    @ViewBuilder
    private func timerLabel(_ session: ActiveSession) -> some View {
        switch session.type {
        case .nap:
            Text(formatDuration(sessionManager.elapsed(for: session)))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.moonClay)
        case .motor:
            if let rem = sessionManager.remaining(for: session) {
                Text(formatDuration(rem))
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(.moonClay)
            }
        case .monitor:
            Text("Max")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.moonClay)
        }
    }

    // MARK: - Expanded card

    private var expandedSheet: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(sessionManager.sessions) { session in
                    expandedSessionView(session)

                    if session.id != sessionManager.sessions.last?.id {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .opacity(0.3)
                    }
                }

                Spacer().frame(height: 20)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func expandedSessionView(_ session: ActiveSession) -> some View {
        switch session.type {
        case .nap:
            expandedNapView(session)
        case .motor:
            expandedMotorView(session)
        case .monitor:
            expandedMonitorView(session)
        }
    }

    // MARK: - Expanded Nap (scenic timer)

    private func expandedNapView(_ session: ActiveSession) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image("icon_nap")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)

                Text("Napping")
                    .font(.body.weight(.semibold))

                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: .green.opacity(0.6), radius: 4)
                    Text("Live")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            // Big scenic timer
            Text(formatDuration(sessionManager.elapsed(for: session)))
                .font(.kepler(44))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(.moonObsidian)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            // Since time
            Text("Since \(session.startTime.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.moonOlive)

            // Stop button
            Button {
                stopSession(session)
            } label: {
                Text("Stop nap")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(.moonClay)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Expanded Motor (circular progress)

    private func expandedMotorView(_ session: ActiveSession) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image("icon_moon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Sleep program")
                        .font(.body.weight(.semibold))
                    Text("Moonboon Motor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)

            // Circular progress
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(.moonApricot.opacity(0.3), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Progress arc
                Circle()
                    .trim(from: 0, to: motorProgress(session) * 0.75)
                    .stroke(.moonClay, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Center time
                VStack(spacing: 2) {
                    if let rem = sessionManager.remaining(for: session) {
                        Text(formatDuration(rem))
                            .font(.kepler(32))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(.moonObsidian)

                        Text("remaining")
                            .font(.caption)
                            .foregroundStyle(.moonOlive)
                    }
                }
            }
            .frame(width: 140, height: 140)
            .padding(.vertical, 4)

            Button {
                stopSession(session)
            } label: {
                Text("Stop program")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(.moonClay)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Expanded Monitor

    private func expandedMonitorView(_ session: ActiveSession) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "video.fill")
                    .font(.title3)
                    .foregroundStyle(.moonClay)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Baby monitor")
                        .font(.body.weight(.semibold))
                    Text("Streaming · \(formatDuration(sessionManager.elapsed(for: session)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Live")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 20)

            Button {
                stopSession(session)
            } label: {
                Text("Stop streaming")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(.moonClay)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func motorProgress(_ session: ActiveSession) -> CGFloat {
        guard let planned = session.plannedDuration, planned > 0 else { return 0 }
        let elapsed = sessionManager.elapsed(for: session)
        return CGFloat(min(1, elapsed / planned))
    }

    private func stopSession(_ session: ActiveSession) {
        withAnimation(.bouncy) {
            if session.type == .nap {
                let duration = sessionManager.elapsed(for: session)
                sessionManager.stopSession(session)
                timelineStore.logNap(duration: duration)
            } else {
                sessionManager.stopSession(session)
            }
            if !sessionManager.hasActiveSessions {
                showSheet = false
            }
        }
    }
}
