import SwiftUI

/// Activity log tab — reuses existing timeline components.
struct TrackerTab: View {
    @Environment(TimelineStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats bar
                DailyStatsBar()

                // Day timeline bar
                DayTimelineBar(segments: store.timelineSegments)

                // Daily report card
                DailyReportCard()

                // Activity feed
                CalendarDayView()

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("Today")
    }
}
