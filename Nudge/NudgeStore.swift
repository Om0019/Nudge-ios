import SwiftUI
import WidgetKit

/// The app's live view of the shared task/theme/layout data. Widgets and the
/// notification content extension read the same App Group storage directly
/// (via `TaskStorage`, `ThemeStore`, `DashboardLayoutStore`) since they run
/// in separate processes and can't observe this object — this class exists
/// so SwiftUI views in the main app get `@Published` updates, and so every
/// mutation in one place also pokes WidgetKit and re-schedules notifications.
@MainActor
final class NudgeStore: ObservableObject {
    @Published var tasks: [NudgeTask]
    @Published var accentColorHex: String
    @Published var appearance: ThemeStore.Appearance
    @Published var sectionOrder: [DashboardSection]
    @Published var hiddenSections: Set<DashboardSection>
    @Published var completionTick = 0 // bumped to force streak/checkmark views to recompute

    init() {
        tasks = TaskStorage.load()
        accentColorHex = ThemeStore.accentColorHex
        appearance = ThemeStore.appearance
        sectionOrder = DashboardLayoutStore.order
        hiddenSections = DashboardLayoutStore.hidden
    }

    var accentColor: Color { Color(hex: accentColorHex) }

    // MARK: - Tasks

    func todaysTasks(on date: Date = .now) -> [NudgeTask] {
        tasks.filter { $0.occurs(on: date) }
            .sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    func upcomingTask(after date: Date = .now) -> NudgeTask? {
        todaysTasks(on: date).first { !CompletionStore.isComplete($0, on: date) && $0.startDate(on: date) >= date.addingTimeInterval(-60 * 15) }
            ?? todaysTasks(on: date).first { !CompletionStore.isComplete($0, on: date) }
    }

    var streak: Int { CompletionStore.streak(tasks: tasks) }

    func addTask(_ task: NudgeTask) {
        tasks.append(task)
        persistTasks()
        NotificationManager.shared.schedule(task)
    }

    func updateTask(_ task: NudgeTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        persistTasks()
        NotificationManager.shared.reschedule(task)
    }

    func deleteTask(_ task: NudgeTask) {
        tasks.removeAll { $0.id == task.id }
        persistTasks()
        NotificationManager.shared.cancel(task)
    }

    func toggleComplete(_ task: NudgeTask, on date: Date = .now) {
        let newValue = !CompletionStore.isComplete(task, on: date)
        CompletionStore.setComplete(task, newValue, on: date)
        completionTick += 1
        reloadWidgets()
    }

    private func persistTasks() {
        TaskStorage.save(tasks)
        reloadWidgets()
    }

    // MARK: - Theme

    func setAccentColorHex(_ hex: String) {
        accentColorHex = hex
        ThemeStore.accentColorHex = hex
        reloadWidgets()
    }

    func setAppearance(_ mode: ThemeStore.Appearance) {
        appearance = mode
        ThemeStore.appearance = mode
    }

    // MARK: - Layout customization

    func moveSections(from source: IndexSet, to destination: Int) {
        sectionOrder.move(fromOffsets: source, toOffset: destination)
        DashboardLayoutStore.order = sectionOrder
    }

    func setSection(_ section: DashboardSection, visible: Bool) {
        if visible { hiddenSections.remove(section) } else { hiddenSections.insert(section) }
        DashboardLayoutStore.hidden = hiddenSections
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
