import Foundation
import CoreServices

/// Lists installed apps and when each was last opened.
/// Needs no permission: the Applications folders are readable by every app,
/// and "last opened" comes from Spotlight, which keeps it for Finder anyway.
struct AppsScanner: SourceScanner {
    let source = DataSource.apps

    /// Apps that can't be removed or that are Less itself. Telling someone to let go of them would be silly.
    static let ignored: Set<String> = ["com.apple.Safari", "app.less.mac"]

    func scan() async -> ScanResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let folders = [URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications")]

        var items: [Item] = []
        let bundles = folders.flatMap { Self.appBundles(in: $0) }
        for url in bundles {
            guard let bundleID = Bundle(url: url)?.bundleIdentifier, !Self.ignored.contains(bundleID) else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            var item = Item(id: "app:\(bundleID)", name: name, kind: .app,
                            category: Categories.forApp(name: name, bundleID: bundleID))
            item.signals.lastUsed = Self.lastOpened(url)
            items.append(item)
        }

        let summary = items.isEmpty
            ? "No apps could be read."
            : "\(items.count) app names and the day you last opened each one."
        return ScanResult(items: items, report: SourceReport(source: source, readable: !items.isEmpty, summary: summary))
    }

    /// .app bundles directly in a folder, plus one level down for suites like "Microsoft Office".
    /// Utilities is skipped: those are parts of macOS, not choices.
    static func appBundles(in folder: URL) -> [URL] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles]) else { return [] }
        var apps: [URL] = []
        for entry in entries {
            if entry.pathExtension == "app" {
                apps.append(entry)
            } else if entry.lastPathComponent != "Utilities",
                      let inner = try? fm.contentsOfDirectory(at: entry, includingPropertiesForKeys: nil,
                                                              options: [.skipsHiddenFiles]) {
                apps += inner.filter { $0.pathExtension == "app" }
            }
        }
        return apps
    }

    static func lastOpened(_ url: URL) -> Date? {
        guard let item = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) else { return nil }
        return MDItemCopyAttribute(item, kMDItemLastUsedDate) as? Date
    }
}
