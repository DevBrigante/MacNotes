import Foundation

struct TemporaryFolder {
    let url: URL

    init() {
        url = URL.temporaryDirectory.appending(
            path: "MacNotesTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func plant(_ text: String, as name: String) {
        try? Data(text.utf8).write(to: url.appending(path: name))
    }

    func text(of name: String) -> String? {
        try? String(contentsOf: url.appending(path: name), encoding: .utf8)
    }

    func holds(_ name: String) -> Bool {
        FileManager.default.fileExists(
            atPath: url.appending(path: name).path(percentEncoded: false))
    }

    func names() -> [String] {
        let contents = try? FileManager.default.contentsOfDirectory(
            atPath: url.path(percentEncoded: false))
        return (contents ?? []).sorted()
    }

    func lockAgainstWriting() {
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o500], ofItemAtPath: url.path(percentEncoded: false))
    }

    func discard() {
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o700], ofItemAtPath: url.path(percentEncoded: false))
        try? FileManager.default.removeItem(at: url)
    }
}
