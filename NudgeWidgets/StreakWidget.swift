import WidgetKit
import SwiftUI

struct StreakWidgetView: View {
    private let streak = WidgetDataSource.streak

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundStyle(.orange)
            Text("\(streak)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(streak == 1 ? "day streak" : "day streak")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .nudgeWidgetBackground()
    }
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NudgeProvider()) { _ in
            StreakWidgetView()
        }
        .configurationDisplayName("Streak")
        .description("How many days in a row you've kept up with your routines.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    NudgeEntry(date: .now)
}
