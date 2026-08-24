import SwiftUI

@main
struct NudgeApp: App {
    @StateObject private var store = NudgeStore()

    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(store.appearance.colorScheme)
                .tint(store.accentColor)
        }
    }
}
