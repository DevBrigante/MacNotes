import CoreGraphics
import Foundation
import Testing

@testable import MacNotes

private let builtIn: CGDirectDisplayID = 1
private let middle: CGDirectDisplayID = 2
private let rightHand: CGDirectDisplayID = 3

struct ActiveDisplayTests {
    @Test func startsOnTheDisplayItIsGiven() {
        #expect(ActiveDisplay(display: builtIn).display == builtIn)
    }

    @Test func theCursorOnTheDisplayItAlreadyOccupiesChangesNothing() {
        var active = ActiveDisplay(display: builtIn)

        active.cursorMoved(to: builtIn, at: 0)
        active.cursorMoved(to: builtIn, at: 10)

        #expect(active.display == builtIn)
    }

    @Test func theCursorHasToRestBeforeThePanelFollowsIt() {
        var active = ActiveDisplay(display: builtIn)

        active.cursorMoved(to: rightHand, at: 0)
        active.cursorMoved(to: rightHand, at: ActiveDisplay.dwell - ActiveDisplay.sampling)

        #expect(active.display == builtIn)

        active.cursorMoved(to: rightHand, at: ActiveDisplay.dwell)

        #expect(active.display == rightHand)
    }

    @Test func crossingADisplayNeverClaimsIt() {
        var active = ActiveDisplay(display: builtIn)

        active.cursorMoved(to: middle, at: 0)
        active.cursorMoved(to: middle, at: 0.25)
        active.cursorMoved(to: rightHand, at: 0.5)
        active.cursorMoved(to: rightHand, at: ActiveDisplay.dwell)

        #expect(active.display == builtIn)

        active.cursorMoved(to: rightHand, at: 0.5 + ActiveDisplay.dwell)

        #expect(active.display == rightHand)
    }

    @Test func turningBackRestartsTheDwell() {
        var active = ActiveDisplay(display: builtIn)

        active.cursorMoved(to: rightHand, at: 0)
        active.cursorMoved(to: builtIn, at: 0.9)
        active.cursorMoved(to: rightHand, at: 1)
        active.cursorMoved(to: rightHand, at: 1.9)

        #expect(active.display == builtIn)

        active.cursorMoved(to: rightHand, at: 2)

        #expect(active.display == rightHand)
    }

    @Test func theDwellIsMeasuredFromTheCursorsArrivalNotTheLastSample() {
        var active = ActiveDisplay(display: builtIn)

        for sample in stride(from: 0.0, to: ActiveDisplay.dwell, by: ActiveDisplay.sampling) {
            active.cursorMoved(to: rightHand, at: sample)
        }

        #expect(active.display == builtIn)

        active.cursorMoved(to: rightHand, at: ActiveDisplay.dwell)

        #expect(active.display == rightHand)
    }

    @Test func settlingOnADisplayEndsTheMigration() {
        var active = ActiveDisplay(display: builtIn)

        active.cursorMoved(to: rightHand, at: 0)
        active.cursorMoved(to: rightHand, at: ActiveDisplay.dwell)
        active.cursorMoved(to: rightHand, at: ActiveDisplay.dwell * 2)

        #expect(active.display == rightHand)
    }

    @Test func theCursorIsSampledSeveralTimesWithinTheDwell() {
        #expect(ActiveDisplay.sampling <= ActiveDisplay.dwell / 2)
    }
}
