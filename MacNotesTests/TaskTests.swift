import Foundation
import Testing

@testable import MacNotes

private let today = Day(year: 2026, month: 9, day: 3)
private let yesterday = Day(year: 2026, month: 9, day: 2)
private let tomorrow = Day(year: 2026, month: 9, day: 4)

struct TaskTests {
    @Test func aTaskWithoutADayIsUnscheduled() {
        #expect(Task(title: "Buy a new charger").isUnscheduled)
        #expect(Task(title: "Buy a new charger", day: today).isUnscheduled == false)
    }

    @Test func completingATaskRecordsTheDayItWasDoneOn() {
        var task = Task(title: "Renew the passport", day: today)

        #expect(task.isCompleted == false)

        task.complete(on: today)

        #expect(task.isCompleted)
        #expect(task.completedOn == today)
    }

    @Test func aDayStillToComeIsKept() {
        let task = Task(title: "Book the flight", day: tomorrow)

        #expect(task.droppingAPassedDay(on: today).day == tomorrow)
    }

    @Test func todayIsNotAPassedDay() {
        let task = Task(title: "Book the flight", day: today)

        #expect(task.droppingAPassedDay(on: today).day == today)
    }

    @Test func aPassedDayIsGivenUpAndTheTaskIsUnscheduledAgain() {
        let task = Task(title: "Book the flight", day: yesterday)

        #expect(task.droppingAPassedDay(on: today).isUnscheduled)
    }

    @Test func aTaskCompletedOnItsDayKeepsThatDayOnceItHasPassed() {
        var task = Task(title: "Book the flight", day: yesterday)
        task.complete(on: yesterday)

        #expect(task.droppingAPassedDay(on: today).day == yesterday)
    }

    @Test func aTaskThatWasNeverScheduledIsLeftAlone() {
        let task = Task(title: "Read the tax letter")

        #expect(task.droppingAPassedDay(on: today) == task)
    }

    @Test func givingUpADayChangesNothingElseAboutTheTask() {
        let task = Task(title: "Book the flight", notes: "Aisle seat", day: yesterday)

        let unscheduled = task.droppingAPassedDay(on: today)

        #expect(unscheduled.id == task.id)
        #expect(unscheduled.title == task.title)
        #expect(unscheduled.notes == task.notes)
        #expect(unscheduled.completedOn == task.completedOn)
    }

    @Test func readsBackEverythingItWrote() throws {
        var done = Task(title: "Renew the passport", notes: "Bring the old one", day: yesterday)
        done.complete(on: yesterday)
        let tasks = [Task(title: "Read the tax letter"), done]

        let encoded = try JSONEncoder().encode(tasks)

        #expect(try JSONDecoder().decode([Task].self, from: encoded) == tasks)
    }

    @Test func leavesOutWhatTheTaskDoesNotCarry() throws {
        let encoded = try JSONEncoder().encode([Task(title: "Read the tax letter")])
        let json = String(decoding: encoded, as: UTF8.self)

        #expect(json.contains("notes") == false)
        #expect(json.contains("day") == false)
        #expect(json.contains("completedOn") == false)
    }
}
