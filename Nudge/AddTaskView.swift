import SwiftUI

private let symbolChoices = [
    "sun.max.fill", "moon.stars.fill", "pills.fill", "brain.head.profile", "figure.walk",
    "book.fill", "cup.and.saucer.fill", "bed.double.fill", "briefcase.fill", "heart.fill",
    "shower.fill", "fork.knife", "dumbbell.fill", "leaf.fill", "checkmark.circle.fill"
]

private let weekdaySymbols = ["M", "T", "W", "T", "F", "S", "S"] // Monday-first, matches repeatDays 1...7

struct AddTaskView: View {
    @EnvironmentObject private var store: NudgeStore
    @Environment(\.dismiss) private var dismiss

    var existingTask: NudgeTask?

    @State private var title: String = ""
    @State private var symbolName: String = symbolChoices[0]
    @State private var colorHex: String = ThemeStore.presetHexes[0]
    @State private var time: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    @State private var durationMinutes: Double = 30
    @State private var repeatDays: Set<Int> = []
    @State private var reminderEnabled = true
    @State private var reminderMinutesBefore: Double = 5
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(symbolChoices, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(symbol == symbolName ? .white : Color(hex: colorHex))
                                .frame(width: 42, height: 42)
                                .background(symbol == symbolName ? Color(hex: colorHex) : Color(hex: colorHex).opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                                .onTapGesture { symbolName = symbol }
                        }
                    }
                    .padding(.vertical, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(ThemeStore.presetHexes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(.primary, lineWidth: hex == colorHex ? 2 : 0))
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Start", selection: $time, displayedComponents: .hourAndMinute)
                    VStack(alignment: .leading) {
                        Text("Duration: \(Int(durationMinutes)) min")
                        Slider(value: $durationMinutes, in: 5...120, step: 5)
                    }
                }

                Section("Repeat") {
                    HStack {
                        ForEach(1...7, id: \.self) { day in
                            Button {
                                if repeatDays.contains(day) { repeatDays.remove(day) } else { repeatDays.insert(day) }
                            } label: {
                                Text(weekdaySymbols[day - 1])
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(width: 32, height: 32)
                                    .foregroundStyle(repeatDays.contains(day) ? .white : .primary)
                                    .background(repeatDays.contains(day) ? Color(hex: colorHex) : Color.gray.opacity(0.15), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text(repeatDays.isEmpty ? "Just today" : "Repeats weekly")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Reminder") {
                    Toggle("Notify me", isOn: $reminderEnabled)
                    if reminderEnabled {
                        VStack(alignment: .leading) {
                            Text(reminderMinutesBefore == 0 ? "At start time" : "\(Int(reminderMinutesBefore)) min before")
                            Slider(value: $reminderMinutesBefore, in: 0...30, step: 5)
                        }
                    }
                }

                if existingTask != nil {
                    Section {
                        Button("Delete task", role: .destructive) {
                            if let existingTask { store.deleteTask(existingTask) }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private func populateIfEditing() {
        guard let task = existingTask else { return }
        title = task.title
        symbolName = task.symbolName
        colorHex = task.colorHex
        time = task.startDate()
        durationMinutes = Double(task.durationMinutes)
        repeatDays = task.repeatDays
        reminderEnabled = task.reminderMinutesBefore != nil
        reminderMinutesBefore = Double(task.reminderMinutesBefore ?? 5)
        notes = task.notes
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let task = NudgeTask(
            id: existingTask?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            symbolName: symbolName,
            colorHex: colorHex,
            hour: components.hour ?? 9,
            minute: components.minute ?? 0,
            durationMinutes: Int(durationMinutes),
            repeatDays: repeatDays,
            reminderMinutesBefore: reminderEnabled ? Int(reminderMinutesBefore) : nil,
            notes: notes
        )

        if existingTask != nil {
            store.updateTask(task)
        } else {
            store.addTask(task)
        }
        dismiss()
    }
}

#Preview {
    AddTaskView().environmentObject(NudgeStore())
}
