import SwiftUI

@main
struct BabyTrackerApp: App {
    @State private var sessionManager = SessionManager()
    @State private var timelineStore = TimelineStore()
    @State private var babyStore = BabyStore()
    @State private var dayNightMode = DayNightMode()
    @State private var napReminder: NapReminderService?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
                .environment(timelineStore)
                .environment(babyStore)
                .environment(dayNightMode)
                .onAppear {
                    sessionManager.babyName = babyStore.baby.name
                    if napReminder == nil {
                        let service = NapReminderService(store: timelineStore, babyStore: babyStore)
                        napReminder = service
                        service.requestPermission()
                    }
                }
                .onChange(of: babyStore.baby.name) {
                    sessionManager.babyName = babyStore.baby.name
                }
                .onChange(of: timelineStore.events.count) {
                    napReminder?.scheduleIfNeeded()
                }
        }
    }
}

enum AppTab: Hashable {
    case schedule, tracker, add, sounds, trends, you
}

struct ContentView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(DayNightMode.self) private var dayNightMode
    @State private var selectedTab: AppTab = .schedule
    @State private var showNapScreen = false
    @State private var showTrackingSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Schedule", systemImage: "clock.fill", value: .schedule) {
                NavigationStack {
                    ScheduleTab()
                }
            }

            Tab("Tracker", systemImage: "list.bullet", value: .tracker) {
                NavigationStack {
                    TrackerTab()
                }
            }

            Tab(value: .add, role: .search) {
                Color.clear
            } label: {
                Label("Add", systemImage: "plus")
            }

            Tab("Sounds", systemImage: "speaker.wave.2.fill", value: .sounds) {
                NavigationStack {
                    SoundsTab()
                }
            }

            Tab("Trends", systemImage: "chart.line.uptrend.xyaxis", value: .trends) {
                NavigationStack {
                    TrendsTab()
                }
            }

            Tab("You", systemImage: "person.fill", value: .you) {
                NavigationStack {
                    YouTab()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.moonClay)
        .onChange(of: selectedTab) { old, new in
            if new == .add {
                selectedTab = old
                showTrackingSheet = true
            }
        }
        .sheet(isPresented: $showTrackingSheet) {
            EventLoggingSheet()
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
}

// MARK: - Tracking Sheet (kept for backward compatibility)

struct TrackingSheet: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(\.dismiss) private var dismiss

    private let sleepTypes: [TimelineEvent.EventType] = [.wake, .nap, .bedtime, .nightWaking]
    private let feedingTypes: [TimelineEvent.EventType] = [.bottle, .nursing, .solids]
    private let careTypes: [TimelineEvent.EventType] = [.diaper]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                Text("Track")
                    .font(.kepler(32))
                    .foregroundStyle(.moonObsidian)
                    .padding(.horizontal, 24)

                // Sleep
                trackingSection("Sleep", types: sleepTypes)

                // Feeding
                trackingSection("Feeding", types: feedingTypes)

                // Care
                trackingSection("Care", types: careTypes)

                Spacer(minLength: 30)
            }
            .padding(.top, 12)
        }
    }

    private func trackingSection(_ title: String, types: [TimelineEvent.EventType]) -> some View {
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
                    trackingButton(type)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func trackingButton(_ type: TimelineEvent.EventType) -> some View {
        Button {
            trackEvent(type)
        } label: {
            VStack(spacing: 10) {
                if let imageName = type.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                } else {
                    Image(systemName: type.sfSymbol)
                        .font(.system(size: 28))
                        .foregroundStyle(.moonClay)
                        .frame(width: 56, height: 56)
                }

                Text(type.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.moonObsidian)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
        }
        .buttonStyle(.glass)
        .disabled(type == .nap && sessionManager.activeNap != nil)
        .opacity(type == .nap && sessionManager.activeNap != nil ? 0.5 : 1)
    }

    private func trackEvent(_ type: TimelineEvent.EventType) {
        switch type {
        case .nap:
            sessionManager.startNap()
        case .bedtime:
            sessionManager.startBedtime()
            timelineStore.logBedtime()
        default:
            timelineStore.logEvent(type)
        }
        dismiss()
    }
}
