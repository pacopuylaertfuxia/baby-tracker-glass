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

struct ContentView: View {
    var body: some View {
        MVPHomeView()
    }
}
