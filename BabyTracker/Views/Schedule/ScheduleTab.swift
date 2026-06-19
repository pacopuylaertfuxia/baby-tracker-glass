import SwiftUI

/// Primary tab — 24h circular clock hero with prediction-forward UX.
/// Switches between day mode and night mode (inline, not a fullscreen cover).
struct ScheduleTab: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(BabyStore.self) private var babyStore
    @Environment(DayNightMode.self) private var dayNightMode

    @State private var showEventSheet = false
    @State private var showNapScreen = false
    @State private var tappedTime: Date?

    // Bedtime wake tracking (inline night mode)
    @State private var isAwake = false
    @State private var wakeCount = 0
    @State private var selectedReason: String?

    private static let reasons = ["Hungry", "Fussy", "Diaper", "Comfort"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if dayNightMode.isNightMode {
                    nightModeContent
                } else {
                    dayModeContent
                }
            }
            .padding(.bottom, 40)
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle(babyStore.baby.name)
        .sheet(isPresented: $showEventSheet) {
            EventLoggingSheet(prefilledTime: tappedTime)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.moonCreme)
        }
        .fullScreenCover(isPresented: $showNapScreen) {
            SleepTrackingScreen(mode: .nap)
        }
        .onChange(of: sessionManager.activeNap != nil) { _, hasNap in
            if hasNap && !showNapScreen {
                showNapScreen = true
            } else if !hasNap {
                showNapScreen = false
            }
        }
    }

    // MARK: - Day Mode

    private var dayModeContent: some View {
        VStack(spacing: 16) {
            // Clock hero with prediction overlay
            clockHero

            // Stats bar
            DailyStatsBar()

            // Last night card
            LastNightCard()

            Spacer(minLength: 20)
        }
    }

    // MARK: - Night Mode

    private var nightModeContent: some View {
        VStack(spacing: 16) {
            // Clock hero (shows live bedtime arc)
            clockHero

            // Wake counter
            if wakeCount > 0 {
                Text("\(wakeCount) wake-up\(wakeCount == 1 ? "" : "s") tonight")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.moonOlive)
                    .padding(.top, 4)
            }

            if isAwake {
                // Awake sub-view with reason pills
                awakeSection
            } else {
                // "Woke up" button
                if sessionManager.activeBedtime != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { isAwake = true }
                    } label: {
                        Text("\(babyStore.baby.name) woke up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.moonWhite)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(.moonSleep, in: Capsule())
                    }
                    .padding(.horizontal, 24)

                    // Good morning
                    Button {
                        endNight()
                    } label: {
                        Text("Good morning")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.moonClay)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(.moonApricot.opacity(0.3), in: Capsule())
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer(minLength: 20)
        }
    }

    // MARK: - Awake Section (night mode)

    private var awakeSection: some View {
        VStack(spacing: 16) {
            Text("Awake")
                .font(.kepler(28))
                .foregroundStyle(.moonObsidian)

            Button {
                logWakeAndSleep()
            } label: {
                Text("Back to sleep")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.moonWhite)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(.moonClay, in: Capsule())
            }
            .padding(.horizontal, 24)

            // Reason pills
            HStack(spacing: 10) {
                ForEach(Self.reasons, id: \.self) { reason in
                    Button {
                        selectedReason = selectedReason == reason ? nil : reason
                    } label: {
                        Text(reason)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selectedReason == reason ? .moonWhite : .moonObsidian)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedReason == reason ? Color.moonClay : Color.moonApricot.opacity(0.3),
                                in: Capsule()
                            )
                    }
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Clock Hero

    private var clockHero: some View {
        ZStack {
            CircularClockView(
                events: timelineStore.events,
                currentTime: sessionManager.currentTick,
                onTapAngle: { date in
                    tappedTime = date
                    showEventSheet = true
                }
            )

            PredictionCountdown()
        }
        .padding(.top, 8)
    }

    // MARK: - Night Actions

    private func logWakeAndSleep() {
        let subtitle = selectedReason
        timelineStore.logNightWake(subtitle: subtitle)
        wakeCount += 1
        selectedReason = nil
        sessionManager.updateBedtimeWakeCount()
        withAnimation(.easeInOut(duration: 0.3)) { isAwake = false }
    }

    private func endNight() {
        timelineStore.logEvent(.wake)
        sessionManager.stopBedtime()
        dayNightMode.enterDayMode()
    }
}
