import Foundation
import UserNotifications

@MainActor @Observable
final class NapReminderService: NSObject, UNUserNotificationCenterDelegate {
    private let store: TimelineStore
    private let babyStore: BabyStore

    // Thresholds
    private static let napGapThreshold: TimeInterval = 2 * 3600    // 2h since last nap/wake
    private static let feedGapThreshold: TimeInterval = 3 * 3600   // 3h since last feed

    // Quiet hours — no notifications
    private static let quietHoursStart = 20
    private static let quietHoursEnd = 6

    // Notification identifiers
    private static let napCategoryID = "NAP_REMINDER"
    private static let feedCategoryID = "FEED_REMINDER"
    static let logNapActionID = "LOG_NAP"
    static let logFeedActionID = "LOG_FEED"
    private static let dismissActionID = "DISMISS"

    private static let napRequestID = "nap_reminder"
    private static let feedRequestID = "feed_reminder"

    var pendingQuickNap = false
    var pendingQuickFeed = false

    init(store: TimelineStore, babyStore: BabyStore) {
        self.store = store
        self.babyStore = babyStore
        super.init()
        setupNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Setup

    private func setupNotificationCategories() {
        // Nap category
        let logNap = UNNotificationAction(
            identifier: Self.logNapActionID,
            title: "Yes, log nap",
            options: [.foreground]
        )
        let napCategory = UNNotificationCategory(
            identifier: Self.napCategoryID,
            actions: [logNap, dismissAction],
            intentIdentifiers: []
        )

        // Feed category
        let logFeed = UNNotificationAction(
            identifier: Self.logFeedActionID,
            title: "Yes, log feed",
            options: [.foreground]
        )
        let feedCategory = UNNotificationCategory(
            identifier: Self.feedCategoryID,
            actions: [logFeed, dismissAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([napCategory, feedCategory])
    }

    private var dismissAction: UNNotificationAction {
        UNNotificationAction(identifier: Self.dismissActionID, title: "Not yet", options: [])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                self.scheduleIfNeeded()
            }
        }
    }

    // MARK: - Scheduling

    func scheduleIfNeeded() {
        scheduleNapReminderIfNeeded()
        scheduleFeedReminderIfNeeded()
    }

    private func scheduleNapReminderIfNeeded() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.napRequestID])

        guard let lastSleepTime = store.lastEvent(ofTypes: [.nap, .wake])?.timestamp else { return }

        let elapsed = Date.now.timeIntervalSince(lastSleepTime)
        let remaining = Self.napGapThreshold - elapsed

        if remaining <= 0 {
            if isQuietHours { return }
            scheduleNapNotification(delay: 1)
        } else {
            scheduleNapNotification(delay: remaining)
        }
    }

    private func scheduleFeedReminderIfNeeded() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.feedRequestID])

        guard let lastFeedTime = store.lastEvent(ofTypes: [.bottle, .nursing, .pumping, .solids])?.timestamp else { return }

        let elapsed = Date.now.timeIntervalSince(lastFeedTime)
        let remaining = Self.feedGapThreshold - elapsed

        if remaining <= 0 {
            if isQuietHours { return }
            scheduleFeedNotification(delay: 1)
        } else {
            scheduleFeedNotification(delay: remaining)
        }
    }

    private func scheduleNapNotification(delay: TimeInterval) {
        let name = babyStore.baby.name
        let content = UNMutableNotificationContent()
        content.title = "Has \(name) napped? 💤"
        content.body = "It's been a while since her last sleep. Tap to log a quick nap, or dismiss if she's still going strong."
        content.sound = .default
        content.categoryIdentifier = Self.napCategoryID

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let request = UNNotificationRequest(identifier: Self.napRequestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleFeedNotification(delay: TimeInterval) {
        let name = babyStore.baby.name
        let content = UNMutableNotificationContent()
        content.title = "Has \(name) eaten? 🍼"
        content.body = "It's been about 3 hours since her last feed. She might be showing hunger cues — rooting, hands to mouth. Quick tap to log it."
        content.sound = .default
        content.categoryIdentifier = Self.feedCategoryID

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let request = UNNotificationRequest(identifier: Self.feedRequestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private var isQuietHours: Bool {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour >= Self.quietHoursStart || hour < Self.quietHoursEnd
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionID = response.actionIdentifier
        let categoryID = response.notification.request.content.categoryIdentifier
        MainActor.assumeIsolated {
            switch actionID {
            case Self.logNapActionID:
                self.store.logEvent(.nap)
                self.pendingQuickNap = true
                self.scheduleIfNeeded()
            case Self.logFeedActionID:
                self.store.logEvent(.bottle)
                self.pendingQuickFeed = true
                self.scheduleIfNeeded()
            default:
                // Dismissed or tapped — snooze for 1h
                if categoryID == Self.napCategoryID {
                    self.scheduleNapNotification(delay: 3600)
                } else if categoryID == Self.feedCategoryID {
                    self.scheduleFeedNotification(delay: 3600)
                }
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
