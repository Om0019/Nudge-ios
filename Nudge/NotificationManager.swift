import UIKit
import UserNotifications

/// Local reminders for tasks, plus the two quick actions (Done / Snooze)
/// that appear on the notification itself — including on the custom
/// "notification widget" rendered by NudgeNotificationContent for the
/// `nudge.task` category.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    static let taskCategoryID = "nudge.task"
    static let doneActionID = "nudge.task.done"
    static let snoozeActionID = "nudge.task.snooze"

    private override init() { super.init() }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func registerCategories() {
        let done = UNNotificationAction(identifier: Self.doneActionID, title: "Mark done", options: [])
        let snooze = UNNotificationAction(identifier: Self.snoozeActionID, title: "Snooze 10m", options: [])
        let category = UNNotificationCategory(
            identifier: Self.taskCategoryID,
            actions: [done, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Scheduling

    func schedule(_ task: NudgeTask) {
        cancel(task)
        guard let leadMinutes = task.reminderMinutesBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = leadMinutes == 0 ? "Starting now — \(task.timeRangeText)" : "Starts in \(leadMinutes) min — \(task.timeRangeText)"
        content.categoryIdentifier = Self.taskCategoryID
        content.sound = .default
        content.userInfo = ["taskID": task.id.uuidString, "symbolName": task.symbolName, "colorHex": task.colorHex, "title": task.title]

        let fireDate = task.startDate().addingTimeInterval(-TimeInterval(leadMinutes * 60))
        var trigger: UNNotificationTrigger

        if task.repeatDays.isEmpty {
            guard fireDate > Date() else { return }
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: requestID(task, weekday: nil), content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        } else {
            // One repeating request per weekday, so "Mon/Wed/Fri" routines
            // don't fire on the days that weren't selected.
            for weekday in task.repeatDays {
                var components = DateComponents()
                components.weekday = weekday == 7 ? 1 : weekday + 1 // our Mon=1...Sun=7 -> Calendar's Sun=1...Sat=7
                let fireComponents = Calendar.current.dateComponents([.hour, .minute], from: fireDate)
                components.hour = fireComponents.hour
                components.minute = fireComponents.minute
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: requestID(task, weekday: weekday), content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func reschedule(_ task: NudgeTask) {
        schedule(task)
    }

    func cancel(_ task: NudgeTask) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(task.id.uuidString) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func requestID(_ task: NudgeTask, weekday: Int?) -> String {
        guard let weekday else { return task.id.uuidString }
        return "\(task.id.uuidString).\(weekday)"
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let taskIDString = response.notification.request.content.userInfo["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString) else {
            completionHandler()
            return
        }

        switch response.actionIdentifier {
        case Self.doneActionID:
            if let task = TaskStorage.load().first(where: { $0.id == taskID }) {
                CompletionStore.setComplete(task, true)
            }
        case Self.snoozeActionID:
            if let task = TaskStorage.load().first(where: { $0.id == taskID }) {
                let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
                let request = UNNotificationRequest(identifier: "\(task.id.uuidString).snooze.\(UUID().uuidString)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        default:
            break
        }
        completionHandler()
    }
}
