import Foundation

nonisolated struct JSONFile<Value: Codable & Sendable>: Sendable {
    enum Reading {
        case value(Value)
        case blank
        case unreadable(Corruption)
    }

    let url: URL

    func read(on day: Day) -> Reading {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return .blank
        }
        do {
            return .value(try JSONDecoder().decode(Value.self, from: Data(contentsOf: url)))
        } catch {
            return .unreadable(setAside(on: day))
        }
    }

    func write(_ value: Value) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    private func setAside(on day: Day) -> Corruption {
        let manager = FileManager.default
        let folder = url.deletingLastPathComponent()
        let stem = "\(url.deletingPathExtension().lastPathComponent).corrupt-\(day.text)"

        var attempt = 1
        while true {
            let name = attempt == 1 ? "\(stem).json" : "\(stem)-\(attempt).json"
            let destination = folder.appending(path: name)
            attempt += 1

            if manager.fileExists(atPath: destination.path(percentEncoded: false)) { continue }
            guard (try? manager.moveItem(at: url, to: destination)) != nil else { break }
            return Corruption(file: url.lastPathComponent, setAside: name)
        }
        return Corruption(file: url.lastPathComponent, setAside: nil)
    }
}

extension JSONFile {
    init(name: String, in folder: URL = .macNotesStore) {
        self.init(url: folder.appending(path: name))
    }
}

extension JSONFile.Reading: Equatable where Value: Equatable {}

extension URL {
    static var macNotesStore: URL {
        let library = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return (library ?? URL.homeDirectory.appending(path: "Library/Application Support"))
            .appending(path: "MacNotes", directoryHint: .isDirectory)
    }
}
