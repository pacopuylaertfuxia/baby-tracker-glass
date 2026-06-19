import SwiftUI

@main
struct BabyTrackerApp: App {
    @State private var sessionManager = SessionManager()
    @State private var timelineStore = TimelineStore()
    @State private var babyStore = BabyStore()
    @State private var napReminder: NapReminderService?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
                .environment(timelineStore)
                .environment(babyStore)
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
    case timeline, devices, add
}

struct ContentView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @State private var selectedTab: AppTab = .timeline
    @State private var showTrackingSheet = false
    @State private var showBedtimeScreen = false
    @State private var showNapScreen = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Timeline", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90", value: .timeline) {
                NavigationStack {
                    TimelineTab()
                }
            }

            Tab("Devices", systemImage: "sensor.fill", value: .devices) {
                NavigationStack {
                    DevicesTab()
                }
            }

            Tab(value: .add, role: .search) {
                Color.clear
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .modifier(BottomAccessoryModifier(
            isEnabled: sessionManager.hasActiveSessions,
            onOpenNapScreen: { showNapScreen = true },
            onOpenBedtimeScreen: { showBedtimeScreen = true }
        ))
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.moonClay)
        .onChange(of: selectedTab) { old, new in
            if new == .add {
                selectedTab = old
                showTrackingSheet = true
            }
        }
        .sheet(isPresented: $showTrackingSheet) {
            TrackingSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showBedtimeScreen) {
            SleepTrackingScreen(mode: .bedtime)
        }
        .fullScreenCover(isPresented: $showNapScreen) {
            SleepTrackingScreen(mode: .nap)
        }
        .onChange(of: sessionManager.activeBedtime != nil) { _, hasBedtime in
            if hasBedtime {
                showBedtimeScreen = true
            } else {
                showBedtimeScreen = false
            }
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

// MARK: - Availability Wrapper

struct BottomAccessoryModifier: ViewModifier {
    let isEnabled: Bool
    var onOpenNapScreen: (() -> Void)?
    var onOpenBedtimeScreen: (() -> Void)?

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content
                .tabViewBottomAccessory(isEnabled: isEnabled) {
                    SessionAccessoryContent(
                        onOpenNapScreen: onOpenNapScreen,
                        onOpenBedtimeScreen: onOpenBedtimeScreen
                    )
                }
        } else {
            content
        }
    }
}

// MARK: - Tracking Sheet

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
