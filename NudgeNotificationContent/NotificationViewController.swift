import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

/// The rich "notification widget" content for the `nudge.task` category —
/// registered in Info.plist below. iOS renders this in place of (and above)
/// the standard notification body, with the Mark Done / Snooze actions
/// declared in `NotificationManager` appearing as buttons underneath.
class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var hostingController: UIHostingController<NotificationCardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 300, height: 110)
    }

    func didReceive(_ notification: UNNotification) {
        let info = notification.request.content.userInfo
        let title = info["title"] as? String ?? notification.request.content.title
        let symbolName = info["symbolName"] as? String ?? "bell.fill"
        let colorHex = info["colorHex"] as? String ?? ThemeStore.defaultColorHex
        let bodyText = notification.request.content.body

        let card = NotificationCardView(title: title, bodyText: bodyText, symbolName: symbolName, colorHex: colorHex)

        if let hostingController {
            hostingController.rootView = card
        } else {
            let controller = UIHostingController(rootView: card)
            hostingController = controller
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(controller.view)
            NSLayoutConstraint.activate([
                controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                controller.view.topAnchor.constraint(equalTo: view.topAnchor),
                controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            controller.didMove(toParent: self)
        }
    }
}

private struct NotificationCardView: View {
    let title: String
    let bodyText: String
    let symbolName: String
    let colorHex: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color(hex: colorHex), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(bodyText)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }
}
