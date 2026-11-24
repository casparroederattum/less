import Foundation
import SQLite3

/// Reads history databases (Screen Time, Safari, Chrome) without disturbing them.
///
/// Browsers keep their database open and locked while running, so we copy it
/// (with its -wal journal, where the newest visits live) into a private temporary
/// folder, read the copy, and delete the copy straight away. The original is never written to.
enum SQLiteCopy {

    /// Returns nil when the file can't be copied, which in practice means macOS said no:
    /// Full Disk Access isn't granted, or the file doesn't exist.
    static func read<T>(_ original: URL, _ body: (OpaquePointer) -> T) -> T? {
        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent("less-\(UUID().uuidString)", isDirectory: true)
        defer { try? fm.removeItem(at: folder) }

        do {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            try fm.copyItem(at: original, to: folder.appendingPathComponent(original.lastPathComponent))
        } catch {
            return nil
        }
        for suffix in ["-wal", "-shm"] {
            let side = URL(fileURLWithPath: original.path + suffix)
            try? fm.copyItem(at: side, to: folder.appendingPathComponent(original.lastPathComponent + suffix))
        }

        var db: OpaquePointer?
        let path = folder.appendingPathComponent(original.lastPathComponent).path
        // Read-write on the *copy*: SQLite needs that to fold the journal in. The original stays untouched.
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK, let db else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }
        return body(db)
    }

    /// Runs one query and hands each row to `row`. Returns false if the query itself failed
    /// (for example when a table doesn't exist on this version of macOS).
    @discardableResult
    static func query(_ db: OpaquePointer, _ sql: String, _ row: (OpaquePointer) -> Void) -> Bool {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return false }
        defer { sqlite3_finalize(statement) }
        while sqlite3_step(statement) == SQLITE_ROW { row(statement) }
        return true
    }

    static func text(_ statement: OpaquePointer, _ column: Int32) -> String? {
        guard let c = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: c)
    }

    static func double(_ statement: OpaquePointer, _ column: Int32) -> Double {
        sqlite3_column_double(statement, column)
    }
}
