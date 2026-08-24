import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: NudgeStore
    @State private var showCustomize = false
    @State private var showAddTask = false
    @State private var focusTask: NudgeTask?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    ForEach(store.sectionOrder.filter { !store.hiddenSections.contains($0) }) { section in
                        sectionView(for: section)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(light: Color(hex: "F7F7F8"), dark: .black).ignoresSafeArea())
            .overlay(alignment: .bottomTrailing) { addButton }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomize = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showCustomize) { CustomizeView() }
            .sheet(isPresented: $showAddTask) { AddTaskView() }
            .sheet(item: $focusTask) { task in FocusTimerView(task: task) }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.nudgeTextSecondary)
            Text("Hey there 👋")
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sectionView(for section: DashboardSection) -> some View {
        switch section {
        case .upNext:
            UpNextCard(onFocus: { focusTask = $0 })
        case .timeline:
            TimelineCard(onFocus: { focusTask = $0 })
        case .streak:
            StreakCard()
        case .focusTimer:
            FocusPromptCard(onStart: { focusTask = $0 })
        }
    }

    private var addButton: some View {
        Button {
            showAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(store.accentColor, in: Circle())
                .shadow(color: store.accentColor.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Up Next

private struct UpNextCard: View {
    @EnvironmentObject private var store: NudgeStore
    let onFocus: (NudgeTask) -> Void

    var body: some View {
        let task = store.upcomingTask()

        VStack(alignment: .leading, spacing: 10) {
            Text("UP NEXT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.nudgeTextSecondary)

            if let task {
                HStack(spacing: 14) {
                    Image(systemName: task.symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Color(hex: task.colorHex), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Text(task.timeRangeText)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(Color.nudgeTextSecondary)
                    }

                    Spacer()

                    Button {
                        onFocus(task)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(store.accentColor, in: Circle())
                    }
                }
            } else {
                Text("Nothing left today — nice work. 🎉")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.nudgeTextSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nudgeCard()
    }
}

// MARK: - Timeline

private struct TimelineCard: View {
    @EnvironmentObject private var store: NudgeStore
    let onFocus: (NudgeTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TODAY'S TIMELINE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.nudgeTextSecondary)

            let tasks = store.todaysTasks()
            if tasks.isEmpty {
                Text("No tasks yet — tap + to add your first one.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.nudgeTextSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        TimelineRow(task: task, onFocus: onFocus)
                        if task.id != tasks.last?.id {
                            Divider().padding(.leading, 46)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nudgeCard()
    }
}

private struct TimelineRow: View {
    @EnvironmentObject private var store: NudgeStore
    let task: NudgeTask
    let onFocus: (NudgeTask) -> Void
    @State private var refreshTick = 0

    private var isComplete: Bool { CompletionStore.isComplete(task) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                store.toggleComplete(task)
                refreshTick += 1
            } label: {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isComplete ? Color(hex: task.colorHex) : Color.nudgeTextSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .strikethrough(isComplete)
                    .foregroundStyle(isComplete ? Color.nudgeTextSecondary : Color.primary)
                Text(task.timeRangeText)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.nudgeTextSecondary)
            }

            Spacer()

            Button {
                onFocus(task)
            } label: {
                Image(systemName: "timer")
                    .foregroundStyle(Color.nudgeTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .id(refreshTick)
    }
}

// MARK: - Streak

private struct StreakCard: View {
    @EnvironmentObject private var store: NudgeStore

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 26))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(store.streak) day streak")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(store.streak > 0 ? "Keep it going!" : "Complete today's routine to start a streak")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.nudgeTextSecondary)
            }
            Spacer()
        }
        .padding(16)
        .nudgeCard()
        .id(store.completionTick)
    }
}

// MARK: - Focus prompt

private struct FocusPromptCard: View {
    @EnvironmentObject private var store: NudgeStore
    let onStart: (NudgeTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FOCUS TIMER")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.nudgeTextSecondary)
            Text("Start a distraction-free timer for anything on your list.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.nudgeTextSecondary)

            if let task = store.upcomingTask() {
                Button("Focus on \"\(task.title)\"") { onStart(task) }
                    .buttonStyle(AccentButtonStyle(accent: store.accentColor))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nudgeCard()
    }
}

#Preview {
    ContentView().environmentObject(NudgeStore())
}
