import AppKit
import SwiftUI

struct TodayPanel: View {
    let model: NotchPanelModel
    let tasks: TaskStore
    let sessions: FocusSessionModel

    @State private var draft = ""
    @State private var choosing: Task.ID?
    @FocusState private var capturing: Bool

    var body: some View {
        VStack(spacing: 0) {
            today
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
            captureField
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var today: some View {
        let day = Day.today()
        let listed = tasks.onTheDay(day)
        if listed.isEmpty {
            nothingForToday
        } else {
            ScrollView {
                TodayRows(
                    tasks: tasks, sessions: sessions, listed: listed, day: day,
                    choosing: $choosing
                )
                .padding(.vertical, 4)
            }
            .scrollIndicators(.never)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var nothingForToday: some View {
        VStack(spacing: 6) {
            Text("Nothing for today")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.75))
            waitingForADay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var waitingForADay: some View {
        let waiting = tasks.unscheduled.count
        if waiting > 0 {
            Text("\(waiting) Unscheduled")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    private var captureField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
            TextField("Add a Task for today", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($capturing)
                .onSubmit(keep)
                .onExitCommand(perform: letGo)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .onChange(of: capturing) { model.captureChanged(hasTheKeyboard: capturing) }
        .onReceive(
            NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)
        ) { _ in
            letGo()
        }
    }

    private func keep() {
        tasks.capture(draft, on: .today())
        draft = ""
    }

    private func letGo() {
        draft = ""
        capturing = false
    }
}

struct TodayRows: View {
    static let rowHeight: CGFloat = 30

    let tasks: TaskStore
    let sessions: FocusSessionModel
    let listed: [Task]
    let day: Day

    @Binding var choosing: Task.ID?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(listed) { row($0) }
        }
    }

    private func row(_ task: Task) -> some View {
        HStack(spacing: 8) {
            completion(task)
            Text(task.title)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? Color.white.opacity(0.4) : Color.white)
            Spacer(minLength: 4)
            session(task)
        }
        .padding(.horizontal, 12)
        .frame(height: Self.rowHeight)
    }

    private func completion(_ task: Task) -> some View {
        Button {
            tasks.complete(task, on: day)
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(task.isCompleted ? 0.5 : 0.7))
        }
        .buttonStyle(.plain)
        .disabled(task.isCompleted)
    }

    @ViewBuilder
    private func session(_ task: Task) -> some View {
        if task.isCompleted {
            EmptyView()
        } else if sessions.session?.task == task.id {
            underway
        } else if choosing == task.id {
            durations(on: task)
        } else {
            Button {
                choosing = task.id
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private var underway: some View {
        HStack(spacing: 6) {
            Text(Countdown.text(sessions.remaining))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(sessions.isRunning ? Color.white : Color.white.opacity(0.5))
            Button {
                if sessions.isRunning { sessions.pause() } else { sessions.resume() }
            } label: {
                Image(systemName: sessions.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private func durations(on task: Task) -> some View {
        HStack(spacing: 4) {
            ForEach(SessionDuration.allCases, id: \.self) { duration in
                Button {
                    sessions.start(duration, on: task.id)
                    choosing = nil
                } label: {
                    Text("\(duration.minutes)")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 22, height: 18)
                        .background(
                            Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
