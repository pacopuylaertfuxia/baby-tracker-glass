import SwiftUI

struct TimelineTab: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(BabyStore.self) private var babyStore

    @State private var mockTimer: Timer?

    /// DailyReportCard shows only in morning (before noon) and evening (after 7pm)
    private var showDailyReport: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 || hour >= 19
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Header ──
                VStack(spacing: 4) {
                    BabyProfileHeader(baby: babyStore.baby)

                    // ── Stats bar (always visible) ──
                    DailyStatsBar()
                        .padding(.top, 4)

                    TimeSinceRow()
                }
                .padding(.bottom, 14)
                .background(alignment: .top) {
                    UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                        .fill(.moonWhite)
                        .padding(.top, -200)
                }

                // ── Daily Report (morning & evening only) ──
                if showDailyReport {
                    DailyReportCard()
                        .padding(.top, 16)
                }

                // ── Last Night ──
                LastNightCard()
                    .padding(.top, 14)

                // ── Daily Rings ──
                DailyRings()
                    .padding(.top, 14)

                // ── Night Wakes ──
                NightWakesCard()
                    .padding(.top, 14)

                // ── Calendar Day View ──
                CalendarDayView()
                    .padding(.top, 14)

                Spacer(minLength: 140)
            }
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Mock: inject a nap after 60 seconds to demo the stats updating
            mockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.6)) {
                        timelineStore.logNap(duration: 38 * 60) // 38 min nap
                    }
                }
            }
        }
        .onDisappear {
            mockTimer?.invalidate()
            mockTimer = nil
        }
    }
}
