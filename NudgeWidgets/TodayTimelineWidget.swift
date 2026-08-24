import WidgetKit
import SwiftUI

struct TodayTimelineWidgetView: View {
    @Environment(\.widgetFamily) private var family
    private let tasks = WidgetDataSource.todaysTasks()

    private var visibleCount: Int { family == .systemLarge ? 6 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TODAY")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)

            if tasks.isEmpty {
                Spacer(minLength: 0)
                Text("Nothing on the timeline yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(tasks.prefix(visibleCount)) { task in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: task.colorHex))
                            .frame(width: 6, height: 6)
                        Text(task.title)
                            .font(.system(size: 12, weight: .medium))
                            .strikethrough(CompletionStore.isComplete(task))
                            .foregroundStyle(CompletionStore.isComplete(task) ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(task.startDate().formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                    }
                }
                if tasks.count > visibleCount {
                    Text("+\(tasks.count - visibleCount) more")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .nudgeWidgetBackground()
    }
}

struct TodayTimelineWidget: Widget {
    let kind = "TodayTimelineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NudgeProvider()) { _ in
            TodayTimelineWidgetView()
        }
        .configurationDisplayName("Today's Timeline")
        .description("Your tasks and routines for the day, in order.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    TodayTimelineWidget()
} timeline: {
    NudgeEntry(date: .now)
}
