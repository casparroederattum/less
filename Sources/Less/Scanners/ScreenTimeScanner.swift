import AppKit
import SQLite3

/// Minutes per day and opens per day for each app, over the last seven days.
///
/// macOS has no public way to read Screen Time on a Mac. The data it has kept for years
/// sits in knowledgeC.db, behind Full Disk Access. Newer macOS versions write some of it
/// elsewhere in a private format, so this may come back empty. When it does, the report
/// says so plainly and the scan carries on without it.
struct ScreenTimeScanner: SourceScanner {
    let source = DataSource.screenTime
    static let days = 7.0

    static var database: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Knowledge/knowledgeC.db")
    }

    func scan() async -> ScanResult {
        guard let totals = Self.readTotals() else {
            return ScanResult(items: [], report: SourceReport(
                source: source, readable: false,
                summary: "Not readable yet. This needs Full Disk Access."))
        }
        guard !totals.isEmpty else {
            return ScanResult(items: [], report: SourceReport(
                source: source, readable: false,
                summary: "This version of macOS keeps app time in a place Less can't read, so it was left out."))
        }

        let items = await MainActor.run { totals.compactMap { Self.item(bundleID: $0.key, total: $0.value) } }
        return ScanResult(items: items, report: SourceReport(
            source: source, readable: true,
            summary: "Minutes and opens per day for \(items.count) apps, from the last seven days."))
    }

    /// bundle id -> (seconds, sessions). nil means the file couldn't be opened at all.
    static func readTotals() -> [String: (seconds: Double, sessions: Int)]? {
        // Dates in this file count seconds from 1 January 2001, the same as Date's reference date.
        let since = Date().timeIntervalSinceReferenceDate - days * 86_400

        return SQLiteCopy.read(database) { db in
            var totals: [String: (seconds: Double, sessions: Int)] = [:]
            // "/app/usage" is the older stream, "/app/inFocus" the newer one. Use the first that has rows,
            // never both, or every minute would count twice. The number is ours, not user input.
            for stream in ["/app/usage", "/app/inFocus"] where totals.isEmpty {
                let sql = """
                    SELECT ZVALUESTRING, ZSTARTDATE, ZENDDATE FROM ZOBJECT
                    WHERE ZSTREAMNAME = '\(stream)' AND ZSTARTDATE > \(since) AND ZVALUESTRING IS NOT NULL
                    """
                SQLiteCopy.query(db, sql) { row in
                    guard let bundleID = SQLiteCopy.text(row, 0) else { return }
                    let seconds = max(0, SQLiteCopy.double(row, 2) - SQLiteCopy.double(row, 1))
                    let old = totals[bundleID] ?? (0, 0)
                    totals[bundleID] = (old.seconds + seconds, old.sessions + 1)
                }
            }
            return totals
        }
    }

    /// Turns raw totals into an item, using the app's real name when this Mac knows it.
    @MainActor
    static func item(bundleID: String, total: (seconds: Double, sessions: Int)) -> Item? {
        let minutesPerDay = total.seconds / 60 / days
        // A minute a day is noise, and Less's own windows shouldn't judge Less.
        guard minutesPerDay >= 1, bundleID != "app.less.mac" else { return nil }

        let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        let name = url?.deletingPathExtension().lastPathComponent ?? bundleID
        var item = Item(id: "app:\(bundleID)", name: name, kind: .app,
                        category: Categories.forApp(name: name, bundleID: bundleID))
        item.signals.minutesPerDay = minutesPerDay
        item.signals.opensPerDay = Double(total.sessions) / days
        return item
    }
}
