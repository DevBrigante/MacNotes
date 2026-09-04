import AppKit
import SwiftUI

struct TodayPanel: View {
    static let cardHeight: CGFloat = 30
    static let cardGap: CGFloat = 6
    static let cardStride: CGFloat = cardHeight + cardGap
    static let cardInset: CGFloat = 2
    static let cardSpace = "TodayCards"

    let model: NotchPanelModel
    let tasks: TaskStore
    let sessions: FocusSessionModel

    @State private var draft = ""
    @State private var allotting: Task.ID?
    @State private var dragging: Task.ID?
    @State private var carried: CGFloat = 0
    @State private var justCompleted: Set<Task.ID> = []
    @State private var accent = SystemAccent.colour()
    @FocusState private var capturing: Bool

    private let day = Day.today()

    var body: some View {
        HStack(spacing: 0) {
            todo
            ActivityGraph(tasks: tasks, month: day)
                .contentShape(Rectangle())
                .onTapGesture { giveUpWhatWasOpen() }
        }
        .foregroundStyle(.white)
        .background(
            Color.black.opacity(0.001)
                .contentShape(Rectangle())
                .onTapGesture { letGo() }
        )
        .overlay { allottingLayer }
        .onChange(of: model.state) { forgetTheCompleted() }
        .onReceive(
            NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)
        ) { _ in
            accent = SystemAccent.colour()
        }
    }

    private var listed: [Task] {
        tasks.listing(on: day, keeping: justCompleted)
    }

    private var todo: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading
            cards
            capture
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heading: some View {
        HStack(spacing: 0) {
            Text("To Do")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.6))
            Spacer(minLength: 4)
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.2))
                .help("The Planner is not built yet")
        }
        .padding(.horizontal, 12)
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture { giveUpWhatWasOpen() }
    }

    @ViewBuilder
    private var cards: some View {
        if listed.isEmpty {
            nothingForToday
        } else {
            ScrollViewReader { scroller in
                ScrollView {
                    TodayCards(
                        model: model, tasks: tasks, sessions: sessions, listed: listed, day: day,
                        accent: accent, allotting: allotting, onAllot: toggleAllotting,
                        onAct: giveUpWhatWasOpen, scroller: scroller,
                        justCompleted: $justCompleted)
                    .coordinateSpace(.named(Self.cardSpace))
                }
            }
            .scrollIndicators(.never)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { giveUpWhatWasOpen() }
        }
    }

    private var nothingForToday: some View {
        Text("Nothing for today")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.35))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { giveUpWhatWasOpen() }
    }

    @ViewBuilder
    private var allottingLayer: some View {
        if let allotting, let task = tasks.task(allotting) {
            ZStack(alignment: .bottomLeading) {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { closeAllotting() }
                picker(task)
                    .padding(.trailing, ActivityGraph.width)
                    .padding(.bottom, 28)
            }
            .transition(.opacity)
        }
    }

    private func picker(_ task: Task) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 14) {
                step("minus", on: task, by: -1)
                VStack(spacing: -1) {
                    Text("\(task.allotted.minutes)")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                    Text("MIN")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .frame(width: 40)
                step("plus", on: task, by: 1)
            }
            HStack(spacing: 4) {
                ForEach(AllottedTime.presets, id: \.self) { preset in
                    preseted(preset, on: task)
                }
            }
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
    }

    private func step(_ symbol: String, on task: Task, by minutes: Int) -> some View {
        Button {
            tasks.allot(task.allotted.stepped(by: minutes), to: task.id)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func preseted(_ minutes: Int, on task: Task) -> some View {
        let chosen = task.allotted.minutes == minutes
        return Button {
            tasks.allot(AllottedTime(minutes: minutes), to: task.id)
        } label: {
            Text("\(minutes)")
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(chosen ? Color.white : Color.white.opacity(0.5))
                .frame(width: 24, height: 16)
                .background(
                    chosen ? accent : Color.white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 4)
                )
        }
        .buttonStyle(.plain)
    }

    private var capture: some View {
        TextField("Add a task", text: $draft)
            .textFieldStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(Color.white.opacity(0.85))
            .focused($capturing)
            .onSubmit(keep)
            .onExitCommand(perform: letGo)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .onChange(of: capturing) { model.captureChanged(hasTheKeyboard: capturing) }
            .onReceive(
                NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)
            ) { _ in
                letGo()
            }
    }

    private func forgetTheCompleted() {
        guard model.state != .expanded else { return }
        justCompleted = []
        allotting = nil
    }

    private func toggleAllotting(_ task: Task) {
        letGo()
        let opening = allotting != task.id
        withAnimation(.easeOut(duration: 0.12)) {
            allotting = opening ? task.id : nil
        }
        model.allottingChanged(isAllotting: opening)
    }

    private func closeAllotting() {
        guard allotting != nil else { return }
        withAnimation(.easeOut(duration: 0.12)) { allotting = nil }
        model.allottingChanged(isAllotting: false)
    }

    private func giveUpWhatWasOpen() {
        letGo()
        closeAllotting()
    }

    private func keep() {
        tasks.capture(draft, on: day)
        draft = ""
    }

    private func letGo() {
        draft = ""
        capturing = false
    }
}

struct TodayCards: View {
    let model: NotchPanelModel
    let tasks: TaskStore
    let sessions: FocusSessionModel
    let listed: [Task]
    let day: Day
    let accent: Color
    let allotting: Task.ID?
    let onAllot: (Task) -> Void
    let onAct: () -> Void
    var scroller: ScrollViewProxy?

    @Binding var justCompleted: Set<Task.ID>

    @State private var dragging: Task.ID?
    @State private var carried: CGFloat = 0

    var body: some View {
        VStack(spacing: TodayPanel.cardGap) {
            ForEach(listed) { card($0) }
        }
        .padding(.vertical, TodayPanel.cardInset)
    }

    private func card(_ task: Task) -> some View {
        HStack(spacing: 8) {
            completion(task)
            Text(task.title)
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.tail)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? Color.white.opacity(0.35) : Color.white)
            Spacer(minLength: 4)
            if task.isCompleted == false {
                allowance(task)
                starter(task)
            }
            handle(task)
        }
        .padding(.horizontal, 10)
        .frame(height: TodayPanel.cardHeight)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
        .padding(.horizontal, 10)
        .id(task.id)
        .offset(y: dragging == task.id ? carried : 0)
        .zIndex(dragging == task.id ? 1 : 0)
    }

    private func completion(_ task: Task) -> some View {
        Button {
            onAct()
            complete(task)
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(task.isCompleted ? 0.4 : 0.6))
        }
        .buttonStyle(.plain)
        .disabled(task.isCompleted)
    }

    @ViewBuilder
    private func allowance(_ task: Task) -> some View {
        if sessions.session?.task == task.id {
            Text(Countdown.text(sessions.remaining))
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundStyle(sessions.isRunning ? Color.white : Color.white.opacity(0.5))
        } else {
            Button {
                onAllot(task)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "timer")
                        .font(.system(size: 8))
                    Text("\(task.allotted.minutes)")
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                    Image(systemName: "chevron.down")
                        .font(.system(size: 6, weight: .bold))
                }
                .foregroundStyle(Color.white.opacity(allotting == task.id ? 0.9 : 0.5))
                .padding(.horizontal, 5)
                .frame(height: 17)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
    }

    private func starter(_ task: Task) -> some View {
        Button {
            onAct()
            begin(task)
        } label: {
            Image(systemName: pausing(task) ? "pause.fill" : "play.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(accent, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func handle(_ task: Task) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Color.white.opacity(dragging == task.id ? 0.75 : 0.3))
            .frame(width: 14, height: TodayPanel.cardHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .named(TodayPanel.cardSpace))
                    .onChanged { gesture in
                        if dragging != task.id {
                            dragging = task.id
                            onAct()
                            model.dragChanged(isDragging: true)
                        }
                        reorder(task, reaching: gesture.location.y)
                        carried = lift(task, to: gesture.location.y)
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.12)) {
                            dragging = nil
                            carried = 0
                        }
                        model.dragChanged(isDragging: false)
                    }
            )
    }


    private func pausing(_ task: Task) -> Bool {
        sessions.session?.task == task.id && sessions.isRunning
    }

    private func begin(_ task: Task) {
        guard sessions.session?.task == task.id else {
            sessions.start(task.allotted, on: task.id)
            return
        }
        if sessions.isRunning { sessions.pause() } else { sessions.resume() }
    }

    private func complete(_ task: Task) {
        justCompleted.insert(task.id)
        tasks.complete(task, on: day)
    }

    private func reorder(_ task: Task, reaching y: CGFloat) {
        guard let from = listed.firstIndex(where: { $0.id == task.id }) else { return }
        let to = TodayCards.landing(of: y, among: listed.count)
        guard to != from else { return }

        withAnimation(.easeOut(duration: 0.12)) {
            tasks.move(within: listed, from: from, to: to)
        }
        scroller?.scrollTo(task.id, anchor: .center)
    }

    private func lift(_ task: Task, to y: CGFloat) -> CGFloat {
        guard let index = listed.firstIndex(where: { $0.id == task.id }) else { return 0 }
        return y - TodayCards.home(of: index)
    }

    static func home(of index: Int) -> CGFloat {
        TodayPanel.cardInset + CGFloat(index) * TodayPanel.cardStride
            + TodayPanel.cardHeight / 2
    }

    static func landing(of y: CGFloat, among count: Int) -> Int {
        let slot = ((y - TodayPanel.cardInset) / TodayPanel.cardStride).rounded(.down)
        return min(max(Int(slot), 0), max(count - 1, 0))
    }
}
