import SwiftUI

/// Full-width event feed — no calendar grid, just clean event cards sorted by time
struct CalendarDayView: View {
    @Environment(TimelineStore.self) private var store
    @State private var eventToDelete: TimelineEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("Activity")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.moonClay)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text("\(visibleEvents.count) events")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonOlive)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // Event list
            VStack(spacing: 10) {
                ForEach(visibleEvents) { event in
                    eventRow(event)
                        .contextMenu {
                            Button(role: .destructive) {
                                eventToDelete = event
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
        .confirmationDialog(
            "Remove this event?",
            isPresented: .init(
                get: { eventToDelete != nil },
                set: { if !$0 { eventToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let event = eventToDelete {
                    withAnimation(.easeOut(duration: 0.3)) {
                        store.deleteEvent(id: event.id)
                    }
                }
                eventToDelete = nil
            }
        } message: {
            if let event = eventToDelete {
                Text("Delete \"\(event.title)\" at \(formatTime(event.timestamp))?")
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: TimelineEvent) -> some View {
        let isDuration = event.endTime != nil

        return HStack(spacing: 14) {
            // Icon
            if let imageName = event.type.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
            } else {
                ZStack {
                    Circle()
                        .fill(event.type.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: event.type.sfSymbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(event.type.color)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.moonObsidian)

                HStack(spacing: 6) {
                    // Time
                    Text(formatTime(event.timestamp))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.moonClay)
                        .monospacedDigit()

                    if let subtitle = event.subtitle {
                        Text("·")
                            .foregroundStyle(.moonStone)
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.moonClay)
                    }
                }
            }

            Spacer()

            // Duration badge for timed events
            if isDuration, let end = event.endTime {
                let mins = Int(end.timeIntervalSince(event.timestamp) / 60)
                Text("\(mins)m")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(event.type.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(event.type.color.opacity(0.1))
                    }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.04), radius: 10, y: 4)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Data

    private var visibleEvents: [TimelineEvent] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return store.events
            .filter { event in
                guard event.type != .nightWaking else { return false }
                guard event.timestamp >= today else { return false }
                let hour = cal.component(.hour, from: event.timestamp)
                return hour >= 6
            }
            .sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        let ampm = hour >= 12 ? "pm" : "am"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }
}
