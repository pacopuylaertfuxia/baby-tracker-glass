import SwiftUI

struct TimelineTab: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(BabyStore.self) private var babyStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // White header card — extends behind status bar
                VStack(spacing: 8) {
                    BabyProfileHeader(baby: babyStore.baby)
                    DayTimelineBar(segments: timelineStore.timelineSegments)
                }
                .padding(.bottom, 16)
                .background(alignment: .top) {
                    // Rounded bottom, but extends far up behind status bar
                    UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
                        .fill(.moonWhite)
                        .padding(.top, -200) // extend well past status bar
                }

                // Events section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Today's events")
                            .font(.title3.weight(.semibold))  // 20pt
                            .foregroundStyle(.moonObsidian)
                        Spacer()
                        Button("See all") {}
                            .font(.body.weight(.medium))  // 17pt
                            .foregroundStyle(.moonClay)
                    }
                    .padding(.horizontal, 8)

                    ForEach(timelineStore.events) { event in
                        TimelineEventRow(event: event)
                    }

                    // Add item card (dashed)
                    TimelineEventRow(
                        event: TimelineEvent(type: .wake, title: "Add item"),
                        isDashed: true
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 20)

                Spacer(minLength: 140)
            }
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("Timeline")
        .toolbarTitleDisplayMode(.inline)
    }

}
