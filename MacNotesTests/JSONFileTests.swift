import Foundation
import Testing

@testable import MacNotes

private let today = Day(year: 2026, month: 9, day: 3)

final class JSONFileTests {
    private let folder = TemporaryFolder()
    private let file: JSONFile<[Task]>

    init() {
        file = JSONFile(name: "tasks.json", in: folder.url)
    }

    deinit {
        folder.discard()
    }

    @Test func aFileThatIsNotThereYetReadsBlank() {
        #expect(file.read(on: today) == .blank)
    }

    @Test func readsBackWhatItWrote() throws {
        let tasks = [
            Task(title: "Read the tax letter"),
            Task(title: "Book the flight", notes: "Aisle seat", day: today),
        ]

        try file.write(tasks)

        #expect(file.read(on: today) == .value(tasks))
    }

    @Test func writesAFileTheUserCanRead() throws {
        try file.write([
            Task(
                id: UUID(uuidString: "00000000-0000-0000-0000-0000000000FF") ?? UUID(),
                title: "Book the flight", day: today)
        ])

        #expect(
            folder.text(of: "tasks.json") == """
                [
                  {
                    "allotted" : 25,
                    "day" : "2026-09-03",
                    "id" : "00000000-0000-0000-0000-0000000000FF",
                    "title" : "Book the flight"
                  }
                ]
                """)
    }

    @Test func makesTheFolderItWritesInto() throws {
        let nested = JSONFile<[Task]>(
            name: "tasks.json", in: folder.url.appending(path: "MacNotes"))

        try nested.write([])

        #expect(nested.read(on: today) == .value([]))
    }

    @Test func setsAFileItCannotParseAsideAndReadsBlank() {
        folder.plant("{ this was never JSON", as: "tasks.json")

        let reading = file.read(on: today)

        #expect(
            reading
                == .unreadable(
                    Corruption(file: "tasks.json", setAside: "tasks.corrupt-2026-09-03.json")))
        #expect(folder.holds("tasks.json") == false)
        #expect(file.read(on: today) == .blank)
    }

    @Test func theBytesItCouldNotReadSurviveUntouched() {
        folder.plant("{ this was never JSON", as: "tasks.json")

        _ = file.read(on: today)

        #expect(folder.text(of: "tasks.corrupt-2026-09-03.json") == "{ this was never JSON")
    }

    @Test func aSecondCorruptionOnTheSameDayKeepsTheFirst() {
        folder.plant("the first one", as: "tasks.json")
        _ = file.read(on: today)
        folder.plant("the second one", as: "tasks.json")

        let reading = file.read(on: today)

        #expect(
            reading
                == .unreadable(
                    Corruption(file: "tasks.json", setAside: "tasks.corrupt-2026-09-03-2.json")))
        #expect(folder.text(of: "tasks.corrupt-2026-09-03.json") == "the first one")
        #expect(folder.text(of: "tasks.corrupt-2026-09-03-2.json") == "the second one")
    }

    @Test func aFileWrittenByALaterVersionCountsAsUnreadable() {
        folder.plant(#"[{ "title": 42 }]"#, as: "tasks.json")

        #expect(
            file.read(on: today)
                == .unreadable(
                    Corruption(file: "tasks.json", setAside: "tasks.corrupt-2026-09-03.json")))
    }

    @Test func aFileItCannotSetAsideIsReportedWithNowhereToGo() {
        folder.plant("{ this was never JSON", as: "tasks.json")
        folder.lockAgainstWriting()

        #expect(file.read(on: today) == .unreadable(Corruption(file: "tasks.json", setAside: nil)))
        #expect(folder.text(of: "tasks.json") == "{ this was never JSON")
    }

    @Test func oneFileGoingBadLeavesTheOthersAlone() {
        folder.plant("{ this was never JSON", as: "tasks.json")
        folder.plant(#"{"launchAtLogin": true}"#, as: "settings.json")

        _ = file.read(on: today)

        #expect(folder.text(of: "settings.json") == #"{"launchAtLogin": true}"#)
        #expect(folder.names() == ["settings.json", "tasks.corrupt-2026-09-03.json"])
    }
}
