import SwiftUI

/// A minimal, single-purpose countdown — no stats, no settings on screen,
/// nothing to make a decision about beyond "start" — the point is to
/// remove friction, not add another surface to fiddle with.
struct FocusTimerView: View {
    @EnvironmentObject private var store: NudgeStore
    @Environment(\.dismiss) private var dismiss
    let task: NudgeTask

    @State private var totalSeconds: Int
    @State private var remainingSeconds: Int
    @State private var isRunning = false
    @State private var timer: Timer?

    init(task: NudgeTask) {
        self.task = task
        let seconds = max(task.durationMinutes, 5) * 60
        _totalSeconds = State(initialValue: seconds)
        _remainingSeconds = State(initialValue: seconds)
    }

    private var progress: Double {
        totalSeconds == 0 ? 0 : 1 - Double(remainingSeconds) / Double(totalSeconds)
    }

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Spacer()
                Button {
                    stop()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(.thinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 8) {
                Image(systemName: task.symbolName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color(hex: task.colorHex))
                Text(task.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(store.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)
                Text(timeText)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 240, height: 240)
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 16) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning ? stop() : start()
                }
                .buttonStyle(AccentButtonStyle(accent: store.accentColor))

                Button("Done") {
                    store.toggleComplete(task)
                    stop()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onDisappear { stop() }
    }

    private var timeText: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stop()
            }
        }
    }

    private func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    FocusTimerView(task: NudgeTask.starterSet[0]).environmentObject(NudgeStore())
}
