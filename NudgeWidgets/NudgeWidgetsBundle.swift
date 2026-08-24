import WidgetKit
import SwiftUI

struct NudgeEntry: TimelineEntry {
    let date: Date
}

struct NudgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> NudgeEntry {
        NudgeEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NudgeEntry) -> Void) {
        completion(NudgeEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NudgeEntry>) -> Void) {
        let now = Date()
        // Refresh every 15 minutes — frequent enough that "Up Next" and the
        // timeline checkmarks stay current through the day, without
        // burning the widget's limited refresh budget the way a tighter
        // interval would. The app also calls WidgetCenter.reloadAllTimelines()
        // on every task edit/completion/theme change, so this interval is
        // just the fallback for whenever the app hasn't been opened.
        let nextRefresh = now.addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [NudgeEntry(date: now)], policy: .after(nextRefresh))
        completion(timeline)
    }
}

extension View {
    /// Every widget renders on the shared accent color, so a widget added
    /// to the Home Screen visually matches whatever the user picked in
    /// Customize — the point of the "customizable visuals" requirement
    /// extending past the app's own screens.
    func nudgeWidgetBackground() -> some View {
        containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

@main
struct NudgeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UpNextWidget()
        TodayTimelineWidget()
        StreakWidget()
    }
}
