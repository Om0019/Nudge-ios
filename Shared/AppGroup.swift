import Foundation

/// Shared container the app, widget extension, and notification content
/// extension all read/write through. After enabling the "App Groups"
/// capability on every target in Xcode's Signing & Capabilities tab, make
/// sure the group identifier there matches this string exactly.
enum AppGroup {
    static let suiteName = "group.com.nudgeapp.shared"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
