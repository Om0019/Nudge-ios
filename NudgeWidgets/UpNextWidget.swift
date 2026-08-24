import WidgetKit
import SwiftUI

struct UpNextWidgetView: View {
    private let task = WidgetDataSource.upcomingTask()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UP NEXT")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)

            if let task {
                HStack(spacing: 8) {
                    Image(systemName: task.symbolName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Color(hex: task.colorHex), in: RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(task.title)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(task.timeRangeText)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                Text("All clear 🎉")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .nudgeWidgetBackground()
    }
}

struct UpNextWidget: Widget {
    let kind = "UpNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NudgeProvider()) { _ in
            UpNextWidgetView()
        }
        .configurationDisplayName("Up Next")
        .description("Your next task or routine block, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    UpNextWidget()
} timeline: {
    NudgeEntry(date: .now)
}
