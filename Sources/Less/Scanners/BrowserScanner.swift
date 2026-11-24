import Foundation
import SQLite3

/// Time and visits per website, from Safari and Chrome, over the last seven days.
///
/// Full addresses pass through memory for a moment only, to pull out the site name.
/// What leaves this file is "youtube.com: 45 min a day, 30 visits a day", nothing more.
struct BrowserScanner: SourceScanner {
    let source = DataSource.browsers
    static let days = 7.0
    /// A gap longer than this means the person walked away; we count only one minute for it.
    static let longestStay = 10.0 * 60
    /// Sites we know nothing about need real time behind them before they get a card.
    static let minutesForUnknownSite = 20.0

    /// One visit: which site, when, and for how long if the browser knows.
    struct Visit { var site: String; var category: Category; var time: Date; var seconds: Double? }

    func scan() async -> ScanResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var visits: [Visit] = []
        var readFrom: [String] = []

        if let safari = Self.safariVisits(home.appendingPathComponent("Library/Safari/History.db")) {
            visits += safari
            readFrom.append("Safari")
        }
        let chromeRoot = home.appendingPathComponent("Library/Application Support/Google/Chrome")
        let chromeProfiles = Self.chromeHistoryFiles(in: chromeRoot)
        var chromeRead = false
        for file in chromeProfiles {
            if let chrome = Self.chromeVisits(file) { visits += chrome; chromeRead = true }
        }
        if chromeRead { readFrom.append("Chrome") }

        let items = Self.items(from: visits)
        let readable = !readFrom.isEmpty
        let summary = readable
            ? "Site names and rough time per day from \(readFrom.joined(separator: " and ")). No addresses, no page titles."
            : "Not readable yet. Safari needs Full Disk Access, and Chrome wasn't found."
        return ScanResult(items: items, report: SourceReport(source: source, readable: readable, summary: summary))
    }

    // MARK: Reading

    static func safariVisits(_ file: URL) -> [Visit]? {
        // Safari counts seconds from 2001, like Date's reference date.
        let since = Date().timeIntervalSinceReferenceDate - days * 86_400
        return SQLiteCopy.read(file) { db in
            var visits: [Visit] = []
            let sql = """
                SELECT history_items.url, history_visits.visit_time
                FROM history_visits JOIN history_items ON history_items.id = history_visits.history_item
                WHERE history_visits.visit_time > \(since)
                """
            SQLiteCopy.query(db, sql) { row in
                guard let address = SQLiteCopy.text(row, 0), let found = site(of: address) else { return }
                let time = Date(timeIntervalSinceReferenceDate: SQLiteCopy.double(row, 1))
                visits.append(Visit(site: found.key, category: found.category, time: time, seconds: nil))
            }
            return visits
        }
    }

    static func chromeVisits(_ file: URL) -> [Visit]? {
        // Chrome counts microseconds since 1601. 11_644_473_600 is the gap between 1601 and 1970 in seconds.
        let gap = 11_644_473_600.0
        let since = (Date().timeIntervalSince1970 - days * 86_400 + gap) * 1_000_000
        return SQLiteCopy.read(file) { db in
            var visits: [Visit] = []
            let sql = """
                SELECT urls.url, visits.visit_time, visits.visit_duration
                FROM visits JOIN urls ON urls.id = visits.url
                WHERE visits.visit_time > \(Int64(since))
                """
            SQLiteCopy.query(db, sql) { row in
                guard let address = SQLiteCopy.text(row, 0), let found = site(of: address) else { return }
                let time = Date(timeIntervalSince1970: SQLiteCopy.double(row, 1) / 1_000_000 - gap)
                let duration = SQLiteCopy.double(row, 2) / 1_000_000
                visits.append(Visit(site: found.key, category: found.category, time: time,
                                    seconds: duration > 0 ? min(duration, longestStay) : nil))
            }
            return visits
        }
    }

    /// "Default", "Profile 1", ... each has its own History file.
    static func chromeHistoryFiles(in root: URL) -> [URL] {
        let fm = FileManager.default
        guard let profiles = try? fm.contentsOfDirectory(atPath: root.path) else { return [] }
        return profiles
            .filter { $0 == "Default" || $0.hasPrefix("Profile ") }
            .map { root.appendingPathComponent($0).appendingPathComponent("History") }
            .filter { fm.fileExists(atPath: $0.path) }
    }

    /// The only thing kept from an address. Local pages and browser-internal pages are dropped.
    static func site(of address: String) -> (key: String, category: Category)? {
        guard let url = URL(string: address), let scheme = url.scheme, scheme.hasPrefix("http"),
              var host = url.host, host.contains(".") else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        if host.hasPrefix("m.") { host.removeFirst(2) }
        return Categories.forHost(host)
    }

    // MARK: Adding up

    /// Visits -> one item per site.
    /// Time per visit: Chrome tells us; for Safari we take the gap until the next visit,
    /// capped, which is a fair guess at how long someone stayed.
    static func items(from visits: [Visit]) -> [Item] {
        let sorted = visits.sorted { $0.time < $1.time }
        var seconds: [String: Double] = [:]
        var count: [String: Int] = [:]
        var category: [String: Category] = [:]

        for (i, visit) in sorted.enumerated() {
            let stay: Double
            if let known = visit.seconds {
                stay = known
            } else if i + 1 < sorted.count {
                let gap = sorted[i + 1].time.timeIntervalSince(visit.time)
                stay = gap > longestStay ? 60 : gap
            } else {
                stay = 60
            }
            seconds[visit.site, default: 0] += stay
            count[visit.site, default: 0] += 1
            category[visit.site] = visit.category
        }

        return seconds.compactMap { site, total in
            let minutes = total / 60 / days
            let cat = category[site] ?? .unknown
            // Known kinds of sites get a card from a few minutes a day; unknown ones need real time.
            guard minutes >= (cat == .unknown ? minutesForUnknownSite : 3) else { return nil }
            var item = Item(id: "web:\(site)", name: site, kind: .website, category: cat)
            item.signals.minutesPerDay = minutes
            item.signals.visitsPerDay = Double(count[site] ?? 0) / days
            return item
        }
    }
}
