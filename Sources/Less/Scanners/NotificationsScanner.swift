import Foundation

/// Which apps may interrupt you. macOS keeps these switches in one preferences file,
/// readable without any extra permission.
///
/// The file stores each app's settings as a number whose bits are switches. Apple doesn't
/// document them. Bits 3 and 4 hold the alert style (banners or alerts); when both are off,
/// the app can't pop up on screen. That is the one thing we read.
struct NotificationsScanner: SourceScanner {
    let source = DataSource.notifications
    static let popsUp = (1 << 3) | (1 << 4)

    static var file: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/com.apple.ncprefs.plist")
    }

    func scan() async -> ScanResult {
        guard let dict = NSDictionary(contentsOf: Self.file) as? [String: Any],
              let apps = dict["apps"] as? [[String: Any]] else {
            return ScanResult(items: [], report: SourceReport(
                source: source, readable: false,
                summary: "This Mac didn't share its notification settings."))
        }

        let installed = Self.installedApps()
        var items: [Item] = []
        for entry in apps {
            guard let bundleID = entry["bundle-id"] as? String,
                  let flags = entry["flags"] as? Int,
                  !bundleID.hasPrefix("com.apple."), !bundleID.hasPrefix("_"),
                  !AppsScanner.ignored.contains(bundleID) else { continue }
            // Only apps that are installed: the file remembers apps long after they're gone.
            guard let url = installed[bundleID] else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            var item = Item(id: "app:\(bundleID)", name: name, kind: .app,
                            category: Categories.forApp(name: name, bundleID: bundleID))
            item.signals.notificationsOn = flags & Self.popsUp != 0
            items.append(item)
        }

        let on = items.filter { $0.signals.notificationsOn == true }.count
        return ScanResult(items: items, report: SourceReport(
            source: source, readable: true,
            summary: "Notification switches for \(items.count) apps. \(on) of them can pop up on your screen."))
    }

    /// bundle id -> app location, read once rather than once per app.
    static func installedApps() -> [String: URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let folders = [URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications")]
        var found: [String: URL] = [:]
        for url in folders.flatMap({ AppsScanner.appBundles(in: $0) }) {
            if let id = Bundle(url: url)?.bundleIdentifier { found[id] = url }
        }
        return found
    }
}
