import SwiftUI

// MARK: - Task model

/// A single task or routine block on the timeline. `repeatDays` empty means
/// "just today"; a non-empty set makes it a recurring routine block that
/// reappears on those weekdays (1 = Monday ... 7 = Sunday, so the set reads
/// left-to-right the same way a weekday picker does).
struct NudgeTask: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var symbolName: String
    var colorHex: String
    var hour: Int
    var minute: Int
    var durationMinutes: Int
    var repeatDays: Set<Int>
    var reminderMinutesBefore: Int?
    var notes: String

    var startComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    /// Today's start time as a concrete `Date`, used for sorting and for
    /// scheduling the local notification trigger.
    func startDate(on day: Date = .now) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? day
    }

    var endDate: Date {
        startDate().addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var timeRangeText: String {
        let start = startDate()
        let end = endDate
        return "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
    }

    /// Whether this block belongs on today's timeline: a one-off task shows
    /// only on the day it was created for (tracked via `repeatDays` being
    /// empty plus a dedicated "one-off date" key), a routine shows on every
    /// matching weekday.
    func occurs(on date: Date) -> Bool {
        if repeatDays.isEmpty { return true }
        let weekday = Calendar.current.component(.weekday, from: date) // 1 = Sun ... 7 = Sat
        let mondayFirst = weekday == 1 ? 7 : weekday - 1
        return repeatDays.contains(mondayFirst)
    }
}

// MARK: - Completion tracking

/// Keyed by `"yyyy-MM-dd|<task id>"` so the same recurring task can be
/// checked off independently on different days.
enum CompletionStore {
    private static let key = "completions"

    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func load() -> [String: Bool] {
        guard let data = AppGroup.defaults.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return [:]
        }
        return dict
    }

    private static func save(_ dict: [String: Bool]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        AppGroup.defaults.set(data, forKey: key)
    }

    static func isComplete(_ task: NudgeTask, on date: Date = .now) -> Bool {
        load()["\(dayKey(for: date))|\(task.id.uuidString)"] ?? false
    }

    static func setComplete(_ task: NudgeTask, _ complete: Bool, on date: Date = .now) {
        var dict = load()
        dict["\(dayKey(for: date))|\(task.id.uuidString)"] = complete
        save(dict)
    }

    /// Consecutive days (ending today or yesterday) where every routine
    /// task scheduled for that day was completed. A day with no routines
    /// scheduled doesn't break the streak — it's simply skipped.
    static func streak(tasks: [NudgeTask]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var day = Date()

        for offset in 0..<365 {
            guard let candidate = calendar.date(byAdding: .day, value: -offset, to: day) else { break }
            let scheduled = tasks.filter { $0.occurs(on: candidate) }
            if scheduled.isEmpty {
                if offset == 0 { continue } // today with nothing due yet shouldn't count against the streak
                day = candidate
                continue
            }
            let allDone = scheduled.allSatisfy { isComplete($0, on: candidate) }
            if allDone {
                streak += 1
            } else if offset == 0 {
                // Today isn't finished yet — don't break the streak on an
                // in-progress day, just don't count it either.
                continue
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Task persistence

enum TaskStorage {
    private static let key = "tasks"

    static func load() -> [NudgeTask] {
        guard let data = AppGroup.defaults.data(forKey: key),
              let tasks = try? JSONDecoder().decode([NudgeTask].self, from: data) else {
            return NudgeTask.starterSet
        }
        return tasks
    }

    static func save(_ tasks: [NudgeTask]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        AppGroup.defaults.set(data, forKey: key)
    }
}

extension NudgeTask {
    /// Shown on first launch so the timeline and widgets aren't empty —
    /// gentle, ADHD-friendly defaults rather than an intimidating blank
    /// slate. Editable/deletable like any other task.
    static let starterSet: [NudgeTask] = [
        NudgeTask(title: "Morning stretch", symbolName: "sun.max.fill", colorHex: "FFB020", hour: 8, minute: 0, durationMinutes: 10, repeatDays: [1, 2, 3, 4, 5], reminderMinutesBefore: 5, notes: ""),
        NudgeTask(title: "Take medication", symbolName: "pills.fill", colorHex: "FF5A8A", hour: 8, minute: 30, durationMinutes: 5, repeatDays: [1, 2, 3, 4, 5, 6, 7], reminderMinutesBefore: 0, notes: ""),
        NudgeTask(title: "Focus block", symbolName: "brain.head.profile", colorHex: "5AA9FF", hour: 10, minute: 0, durationMinutes: 50, repeatDays: [1, 2, 3, 4, 5], reminderMinutesBefore: 5, notes: "Phone on Do Not Disturb"),
        NudgeTask(title: "Lunch + walk", symbolName: "figure.walk", colorHex: "3ECF8E", hour: 12, minute: 30, durationMinutes: 40, repeatDays: [1, 2, 3, 4, 5], reminderMinutesBefore: 0, notes: ""),
        NudgeTask(title: "Wind down", symbolName: "moon.stars.fill", colorHex: "9B7BFF", hour: 21, minute: 30, durationMinutes: 20, repeatDays: [1, 2, 3, 4, 5, 6, 7], reminderMinutesBefore: 10, notes: "Screens away, lights low")
    ]
}

// MARK: - Theme / customization

/// The accent color and appearance the user picked in Customize — read by
/// the app, the widgets, and the notification content extension so all
/// three stay visually in sync.
enum ThemeStore {
    private static let colorKey = "accentColorHex"
    private static let appearanceKey = "appearanceMode"

    /// Same warm orange as the app icon's gradient midpoint.
    static let defaultColorHex = "FF6A1D"

    static let presetHexes = [
        "FF6A1D", // Nudge orange (default)
        "FF5A8A", // coral
        "FFB020", // sunflower
        "3ECF8E", // mint
        "5AA9FF", // sky
        "9B7BFF", // lavender
        "FF3B7F", // pink
        "5AC8C8"  // teal
    ]

    static var accentColorHex: String {
        get { AppGroup.defaults.string(forKey: colorKey) ?? defaultColorHex }
        set { AppGroup.defaults.set(newValue, forKey: colorKey) }
    }

    static var accentColor: Color { Color(hex: accentColorHex) }

    enum Appearance: String, CaseIterable {
        case system, light, dark

        var label: String {
            switch self {
            case .system: return "Match device"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    static var appearance: Appearance {
        get { Appearance(rawValue: AppGroup.defaults.string(forKey: appearanceKey) ?? "") ?? .system }
        set { AppGroup.defaults.set(newValue.rawValue, forKey: appearanceKey) }
    }
}

/// The customizable sections of the Today screen — what shows, and in what
/// order. Widgets stick to their own fixed layouts, but the main app honors
/// this so a user who only wants a bare timeline can hide the rest.
enum DashboardSection: String, Codable, CaseIterable, Identifiable {
    case upNext, timeline, streak, focusTimer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upNext: return "Up Next"
        case .timeline: return "Today's Timeline"
        case .streak: return "Streak"
        case .focusTimer: return "Focus Timer"
        }
    }

    var symbolName: String {
        switch self {
        case .upNext: return "arrow.right.circle.fill"
        case .timeline: return "list.bullet.rectangle.fill"
        case .streak: return "flame.fill"
        case .focusTimer: return "timer"
        }
    }
}

enum DashboardLayoutStore {
    private static let orderKey = "dashboardOrder"
    private static let hiddenKey = "dashboardHidden"

    static var order: [DashboardSection] {
        get {
            guard let raw = AppGroup.defaults.array(forKey: orderKey) as? [String] else {
                return DashboardSection.allCases
            }
            let saved = raw.compactMap { DashboardSection(rawValue: $0) }
            // Any section added in a later app update that isn't in the
            // saved order yet gets appended rather than dropped.
            let missing = DashboardSection.allCases.filter { !saved.contains($0) }
            return saved + missing
        }
        set { AppGroup.defaults.set(newValue.map(\.rawValue), forKey: orderKey) }
    }

    static var hidden: Set<DashboardSection> {
        get {
            let raw = AppGroup.defaults.array(forKey: hiddenKey) as? [String] ?? []
            return Set(raw.compactMap { DashboardSection(rawValue: $0) })
        }
        set { AppGroup.defaults.set(newValue.map(\.rawValue), forKey: hiddenKey) }
    }

    static func isVisible(_ section: DashboardSection) -> Bool {
        !hidden.contains(section)
    }
}

// MARK: - Read-only data access for widgets & the notification content extension

/// Both extensions run in their own process and can't hold the app's
/// `NudgeStore`, so they read the same App Group storage through these pure
/// functions instead — same task-selection logic as `NudgeStore`, just
/// without the `@Published`/`ObservableObject` machinery that only makes
/// sense inside the main app.
enum WidgetDataSource {
    static func todaysTasks(on date: Date = .now) -> [NudgeTask] {
        TaskStorage.load()
            .filter { $0.occurs(on: date) }
            .sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    static func upcomingTask(after date: Date = .now) -> NudgeTask? {
        let tasks = todaysTasks(on: date)
        return tasks.first { !CompletionStore.isComplete($0, on: date) && $0.startDate(on: date) >= date.addingTimeInterval(-60 * 15) }
            ?? tasks.first { !CompletionStore.isComplete($0, on: date) }
    }

    static var streak: Int { CompletionStore.streak(tasks: TaskStorage.load()) }
}

// MARK: - Color hex helper (shared by app, widgets, and notification content)

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
