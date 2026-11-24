import Foundation

/// One finished scan. Kept so the next scan can show what changed.
struct ScanRecord: Codable {
    var date: Date
    var items: [Item]
    /// Apps that looked fine and got no card. Counted, not listed, so the results stay short.
    var quietCount: Int
}

/// Everything Less remembers, in one small file.
struct SavedState: Codable {
    var choices: [String: Bool] = [:]          // DataSource.rawValue -> allowed
    var reports: [SourceReport] = []
    var lastScan: ScanRecord?
    var previousScan: ScanRecord?
    var added: [Item] = []                       // things added from "Fill the gaps"
}

/// Reads and writes the one file in Application Support.
/// Plain JSON on purpose: anyone can open it and see there is nothing hidden.
enum Store {
    static var folder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Less", isDirectory: true)
    }

    static var file: URL { folder.appendingPathComponent("less.json") }

    static func load() -> SavedState {
        guard let data = try? Data(contentsOf: file),
              let state = try? decoder.decode(SavedState.self, from: data) else { return SavedState() }
        return state
    }

    static func save(_ state: SavedState) {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try encoder.encode(state)
            // Atomic, so a crash halfway through never leaves a broken file.
            try data.write(to: file, options: .atomic)
        } catch {
            NSLog("Less: could not save: \(error.localizedDescription)")
        }
    }

    /// "Delete everything" has to mean everything: the folder goes, not just the contents.
    static func wipe() {
        try? FileManager.default.removeItem(at: folder)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
