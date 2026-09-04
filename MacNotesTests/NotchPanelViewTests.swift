import CoreGraphics
import Foundation
import SwiftUI
import Testing

@testable import MacNotes

@MainActor
final class NotchPanelViewTests {
    private let folder = TemporaryFolder()

    deinit {
        folder.discard()
    }

    private let physical = NotchMetrics(
        screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        notchRect: CGRect(x: 656, y: 945, width: 200, height: 37),
        hasPhysicalNotch: true
    )

    private let simulated = NotchMetrics(
        screenFrame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        notchRect: CGRect(x: 1180, y: 1416, width: 200, height: 24),
        hasPhysicalNotch: false
    )

    @Test func theNotchIsPaintedOverEvenWhereItIsPhysical() throws {
        let model = collapsed()
        let pixels = try render(model, on: physical)
        let gap = physical.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.midX, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: gap.minX + 1, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: gap.maxX - 1, y: gap.midY) == 255)
    }

    @Test func bothFlanksAreDrawnOn() throws {
        let model = collapsed()
        let pixels = try render(model, on: physical)
        let gap = physical.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.minX / 2, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: (gap.maxX + CGFloat(pixels.width)) / 2, y: gap.midY) == 255)
    }

    @Test func hiddenDrawsNothingAtAllWhereTheNotchIsPhysical() throws {
        let pixels = try render(NotchPanelModel(), on: physical)

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4) {
            for y in stride(from: 1.0, to: Double(pixels.height) - 1, by: 4) {
                #expect(pixels.alpha(atX: x, y: y) == 0)
            }
        }
    }

    @Test func expandedFillsTheWholeMenuBarStrip() throws {
        let model = expanded()
        let pixels = try render(model, on: physical)
        let strip = physical.notchGap(for: model.state)

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4) {
            #expect(pixels.alpha(atX: x, y: strip.midY) == 255)
        }
    }

    @Test func collapsedDrawsTheSimulatedNotchAsOneStripWithItsFlanks() throws {
        let model = collapsed()
        let pixels = try render(model, on: simulated)
        let gap = simulated.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.midX, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: gap.minX + 1, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: gap.maxX - 1, y: gap.midY) == 255)
    }

    @Test func expandedFillsTheStripOnASimulatedNotchTheSameWay() throws {
        let model = expanded()
        let pixels = try render(model, on: simulated)
        let strip = simulated.notchGap(for: model.state)

        #expect(pixels.alpha(atX: strip.midX, y: strip.midY) == 255)
        #expect(pixels.alpha(atX: strip.minX / 2, y: strip.midY) == 255)
        #expect(pixels.alpha(atX: (strip.maxX + CGFloat(pixels.width)) / 2, y: strip.midY) == 255)
    }

    @Test func hiddenMarksTheSimulatedNotchAndNothingElse() throws {
        let pixels = try render(NotchPanelModel(), on: simulated)
        let centre = (x: Double(pixels.width) / 2, y: Double(pixels.height) / 2)

        #expect(pixels.alpha(atX: centre.x, y: centre.y) == 255)

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4)
        where abs(x - centre.x) > 12 {
            for y in stride(from: 1.0, to: Double(pixels.height) - 1, by: 4) {
                #expect(pixels.alpha(atX: x, y: y) == 0)
            }
        }
    }

    @Test(arguments: [0.4, 0.7, 1.0])
    func theNotchStaysCentredWhileThePanelIsStillGrowing(fraction: CGFloat) throws {
        let model = expanded()
        let pixels = try render(model, on: simulated, grownTo: fraction)
        let strip = simulated.notchGap(for: model.state)

        for x in stride(from: 0.0, to: Double(pixels.width) / 2, by: 2) {
            let mirrored = Double(pixels.width) - 1 - x
            #expect(pixels.alpha(atX: x, y: strip.midY) == pixels.alpha(atX: mirrored, y: strip.midY))
        }
    }

    @Test func theTraySweepsDownOneSideAlongTheBottomAndUpTheOther() throws {
        let pixels = try render(collapsed(), on: physical, sessions: running(0.95))

        #expect(accent(pixels, atX: 5, y: 20))
        #expect(accent(pixels, atX: 172, y: 42))
        #expect(accent(pixels, atX: 339, y: 30))
        #expect(accent(pixels, atX: 339, y: 8) == false)
    }

    @Test func theTrayGrowsFromTheTopLeftOnwardsAndDoesNotDrain() throws {
        let pixels = try render(collapsed(), on: physical, sessions: running(0.2))

        #expect(accent(pixels, atX: 5, y: 20))
        #expect(accent(pixels, atX: 30, y: 42))
        #expect(accent(pixels, atX: 200, y: 42) == false)
        #expect(accent(pixels, atX: 339, y: 30) == false)
    }

    @Test func theTrayCrossesBelowTheCameraRatherThanStoppingAtIt() throws {
        let model = collapsed()
        let pixels = try render(model, on: physical, sessions: running(0.95))
        let gap = physical.notchGap(for: model.state)
        let bottom = physical.panelFrame(for: model.state).height - 5

        #expect(accent(pixels, atX: gap.minX + 1, y: bottom))
        #expect(accent(pixels, atX: gap.midX, y: bottom))
        #expect(accent(pixels, atX: gap.maxX - 1, y: bottom))
    }

    @Test func thereIsNoTrayWithoutASession() throws {
        let pixels = try render(collapsed(), on: physical)

        #expect(accent(pixels, atX: 5, y: 15) == false)
        #expect(accent(pixels, atX: 339, y: 15) == false)
    }

    @Test func theHiddenPanelDrawsNoTrayEvenWhileASessionRuns() throws {
        let pixels = try render(NotchPanelModel(), on: physical, sessions: running(0.5))

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4) {
            for y in stride(from: 1.0, to: Double(pixels.height) - 1, by: 4) {
                #expect(pixels.alpha(atX: x, y: y) == 0)
            }
        }
    }

    @Test func theExpandedTrayTracesTheOutlineBesideTheStripToo() throws {
        let pixels = try render(expanded(), on: physical, sessions: running(0.5))

        #expect(accent(pixels, atX: 5, y: 15))
        #expect(accent(pixels, atX: 5, y: 100))
        #expect(accent(pixels, atX: 459, y: 100) == false)
    }

    private func accent(_ pixels: Pixels, atX x: CGFloat, y: CGFloat) -> Bool {
        let pixel = pixels.pixel(atX: x, y: y)
        return pixel.alpha > 0 && (pixel.red > 0 || pixel.green > 0 || pixel.blue > 0)
    }

    private func idle() -> FocusSessionModel {
        FocusSessionModel(now: { 0 }, tick: 60, workspace: NotificationCenter())
    }

    private func store(_ planned: [Task] = []) -> TaskStore {
        let store = TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60)
        planned.forEach(store.add)
        return store
    }

    private func running(_ fraction: Double, on task: Task.ID = UUID()) -> FocusSessionModel {
        let clock = Clock()
        let sessions = FocusSessionModel(
            now: { clock.now }, tick: 60, workspace: NotificationCenter())
        sessions.start(.init(minutes: 15), on: task)
        clock.now = AllottedTime(minutes: 15).seconds * fraction
        sessions.pause()
        return sessions
    }

    private func collapsed() -> NotchPanelModel {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)
        return model
    }

    private func expanded() -> NotchPanelModel {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        return model
    }

    private func render(
        _ model: NotchPanelModel,
        on metrics: NotchMetrics,
        sessions: FocusSessionModel? = nil,
        tasks: TaskStore? = nil,
        grownTo fraction: CGFloat = 1
    ) throws -> Pixels {
        let frame = metrics.panelFrame(for: model.state)
        return try Pixels(
            NotchPanelView(
                metrics: metrics, model: model, sessions: sessions ?? idle(),
                tasks: tasks ?? store()),
            width: (frame.width * fraction).rounded(),
            height: (frame.height * fraction).rounded())
    }

    @Test func theCollapsedStripWritesTheTaskEitherSideOfTheNotch() throws {
        let underway = Task(title: "Book the flight", day: .today())
        let model = collapsed()
        let pixels = try render(
            model, on: physical, sessions: running(0.5, on: underway.id),
            tasks: store([underway]))
        let gap = physical.notchGap(for: model.state)

        #expect(pixels.written(across: 8...Int(gap.minX) - 8, down: 8...26))
        #expect(pixels.written(across: Int(gap.maxX) + 8...pixels.width - 14, down: 8...26))
    }

    @Test func theExpandedStripIsPlainBlackWithNoReadoutOnIt() throws {
        let underway = Task(title: "Book the flight", day: .today())
        let model = expanded()
        let pixels = try render(
            model, on: physical, sessions: running(0.5, on: underway.id),
            tasks: store([underway]))
        let strip = physical.notchGap(for: model.state)

        for x in stride(from: 20.0, to: Double(pixels.width) - 20, by: 4) {
            let pixel = pixels.pixel(atX: x, y: strip.midY)
            #expect(pixel.alpha == 255)
            #expect(pixel.red == 0 && pixel.green == 0 && pixel.blue == 0)
        }
    }
}

@MainActor
private final class Clock {
    var now: TimeInterval = 0
}
