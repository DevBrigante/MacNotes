import SwiftUI

struct PlannerCard: View {
    let planner: PlannerModel
    let task: Task

    @State private var allotting = false
    @State private var givingADay = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row
            if planner.editing == task.id {
                NotesField(task: task, tasks: planner.tasks)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private var row: some View {
        HStack(spacing: 8) {
            completion
            title
            Spacer(minLength: 8)
            dayChip
            HStack(spacing: 8) {
                allowance
                starter
            }
            .frame(width: 76, alignment: .trailing)
            remover
            handle
        }
    }

    private var handle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .frame(width: 14)
    }

    private var completion: some View {
        Button {
            planner.toggleCompletion(of: task)
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var title: some View {
        Button {
            planner.editing = planner.editing == task.id ? nil : task.id
        } label: {
            HStack(spacing: 5) {
                Text(task.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                if task.notes != nil {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var dayChip: some View {
        Button {
            givingADay = true
        } label: {
            Text(Self.dayLabel(for: task.day, on: planner.today))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(task.day == nil ? .tertiary : .secondary)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $givingADay, arrowEdge: .bottom) {
            DayPicker(
                task: task, today: planner.today, tasks: planner.tasks, showing: $givingADay)
        }
    }

    @ViewBuilder
    private var allowance: some View {
        if planner.sessions.session?.task == task.id {
            Text(Countdown.text(planner.sessions.remaining))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(planner.sessions.isRunning ? .primary : .secondary)
                .frame(width: 44)
        } else if task.isCompleted == false {
            Button {
                allotting = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 9))
                    Text("\(task.allotted.minutes)")
                        .font(.system(size: 11, weight: .medium).monospacedDigit())
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $allotting, arrowEdge: .bottom) {
                AllottedTimePicker(task: task, tasks: planner.tasks)
            }
        }
    }

    @ViewBuilder
    private var starter: some View {
        if task.isCompleted == false {
            Button {
                planner.sessions.startOrPause(task)
            } label: {
                Image(systemName: pausing ? "pause.fill" : "play.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var remover: some View {
        Button {
            planner.delete(task)
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var pausing: Bool {
        planner.sessions.session?.task == task.id && planner.sessions.isRunning
    }

    static func dayLabel(for day: Day?, on today: Day, in calendar: Calendar = .current) -> String {
        guard let day else { return "No Day" }
        if day == today { return "Today" }
        if day == today.stepped(by: 1, in: calendar) { return "Tomorrow" }
        if day == today.stepped(by: -1, in: calendar) { return "Yesterday" }
        guard let date = day.date(in: calendar) else { return day.text }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

struct NotesField: View {
    let task: Task
    let tasks: TaskStore

    @State private var written = ""

    var body: some View {
        TextEditor(text: $written)
            .font(.system(size: 12))
            .scrollContentBackground(.hidden)
            .frame(height: 68)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topLeading) {
                if written.isEmpty {
                    Text("Notes")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .onAppear { written = task.notes ?? "" }
            .onChange(of: written) { tasks.note(written, on: task.id) }
    }
}

struct AllottedTimePicker: View {
    let task: Task
    let tasks: TaskStore

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                step("minus", by: -1)
                VStack(spacing: -2) {
                    Text("\(task.allotted.minutes)")
                        .font(.system(size: 17, weight: .semibold).monospacedDigit())
                    Text("MIN")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 44)
                step("plus", by: 1)
            }
            HStack(spacing: 4) {
                ForEach(AllottedTime.presets, id: \.self) { preset in
                    preseted(preset)
                }
            }
        }
        .padding(12)
    }

    private func step(_ symbol: String, by minutes: Int) -> some View {
        Button {
            tasks.allot(task.allotted.stepped(by: minutes), to: task.id)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func preseted(_ minutes: Int) -> some View {
        let chosen = task.allotted.minutes == minutes
        return Button {
            tasks.allot(AllottedTime(minutes: minutes), to: task.id)
        } label: {
            Text("\(minutes)")
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundStyle(chosen ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                .frame(width: 28, height: 18)
                .background(
                    chosen ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.primary.opacity(0.08)),
                    in: RoundedRectangle(cornerRadius: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

struct DayPicker: View {
    let task: Task
    let today: Day
    let tasks: TaskStore

    @Binding var showing: Bool
    @State private var month: Day

    init(task: Task, today: Day, tasks: TaskStore, showing: Binding<Bool>) {
        self.task = task
        self.today = today
        self.tasks = tasks
        _showing = showing
        _month = State(initialValue: (task.day ?? today).firstOfItsMonth)
    }

    var body: some View {
        VStack(spacing: 10) {
            MonthCalendar(
                month: $month,
                selected: task.day,
                today: today,
                carries: { tasks.onTheDay($0).isEmpty == false },
                pick: { give($0) }
            )
            HStack(spacing: 8) {
                Button("Today") { give(today) }
                Button("No Day") { give(nil) }
            }
        }
        .padding(12)
    }

    private func give(_ day: Day?) {
        tasks.give(day, to: task.id)
        showing = false
    }
}
