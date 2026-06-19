import SwiftUI

/// Bottom sheet for logging events, triggered by clock tap or FAB.
/// Pre-fills tapped time (snapped to nearest 15 min).
struct EventLoggingSheet: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(\.dismiss) private var dismiss

    var prefilledTime: Date?

    private let sleepTypes: [TimelineEvent.EventType] = [.wake, .nap, .bedtime, .nightWaking]
    private let feedingTypes: [TimelineEvent.EventType] = [.bottle, .nursing, .solids]
    private let careTypes: [TimelineEvent.EventType] = [.diaper, .temperature, .medicine]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header with optional time
                HStack {
                    Text("Log event")
                        .font(.kepler(32))
                        .foregroundStyle(.moonObsidian)

                    Spacer()

                    if let time = prefilledTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.moonClay)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.moonApricot.opacity(0.2), in: Capsule())
                    }
                }
                .padding(.horizontal, 24)

                // Sleep
                eventSection("Sleep", types: sleepTypes)

                // Feeding
                eventSection("Feeding", types: feedingTypes)

                // Care
                eventSection("Care", types: careTypes)

                Spacer(minLength: 30)
            }
            .padding(.top, 12)
        }
    }

    private func eventSection(_ title: String, types: [TimelineEvent.EventType]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.moonClay)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, 24)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(types, id: \.rawValue) { type in
                    eventButton(type)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func eventButton(_ type: TimelineEvent.EventType) -> some View {
        Button {
            logEvent(type)
        } label: {
            VStack(spacing: 10) {
                if let imageName = type.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                } else {
                    Image(systemName: type.sfSymbol)
                        .font(.system(size: 24))
                        .foregroundStyle(.moonClay)
                        .frame(width: 48, height: 48)
                }

                Text(type.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.moonObsidian)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.moonWhite)
                    .shadow(color: .moonBlack.opacity(0.04), radius: 8, y: 3)
            }
        }
        .buttonStyle(.plain)
        .disabled(type == .nap && sessionManager.activeNap != nil)
        .opacity(type == .nap && sessionManager.activeNap != nil ? 0.5 : 1)
    }

    private func logEvent(_ type: TimelineEvent.EventType) {
        switch type {
        case .nap:
            sessionManager.startNap()
        case .bedtime:
            sessionManager.startBedtime()
            timelineStore.logBedtime()
        default:
            if let time = prefilledTime {
                timelineStore.addEvent(TimelineEvent(type: type, title: type.displayName, timestamp: time))
            } else {
                timelineStore.logEvent(type)
            }
        }
        dismiss()
    }
}
