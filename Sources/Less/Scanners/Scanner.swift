import Foundation

/// What every scanner hands back: some items, and one honest line about what it could read.
struct ScanResult {
    var items: [Item]
    var report: SourceReport
}

/// One scanner per data source. Each is small, knows only its own corner,
/// and never throws: when something can't be read, it says so in the report instead.
protocol SourceScanner {
    var source: DataSource { get }
    func scan() async -> ScanResult
}

enum Scanners {
    /// Real scanners, or made-up ones when started with --demo (to try the screens without permissions).
    static func all(demo: Bool) -> [any SourceScanner] {
        if demo { return DataSource.allCases.map { StubScanner(source: $0) as any SourceScanner } }
        return [
            AppsScanner(),
            ScreenTimeScanner(),
            BrowserScanner(),
            LoginItemsScanner(),
            NotificationsScanner(),
            BluetoothScanner(),
            NetworkDevicesScanner(),
        ]
    }

    /// Several scanners can describe the same app (time, notifications, login).
    /// They agree on the id, so we fold them into one item here.
    static func combine(_ items: [Item]) -> [Item] {
        var byID: [String: Item] = [:]
        var order: [String] = []
        for item in items {
            if var existing = byID[item.id] {
                existing.signals.merge(item.signals)
                if existing.category == .unknown { existing.category = item.category }
                // A real app name beats a bundle id used as a placeholder.
                if existing.name.contains("."), !item.name.contains(".") { existing.name = item.name }
                byID[item.id] = existing
            } else {
                byID[item.id] = item
                order.append(item.id)
            }
        }
        return order.compactMap { byID[$0] }
    }
}
