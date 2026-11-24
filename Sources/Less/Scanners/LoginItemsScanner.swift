import AppKit

/// What starts on its own, from three places:
///  1. Login items ("Open at Login"), asked of System Events. macOS asks the person once.
///  2. Launch agents: small files that tell macOS to start a helper for an app.
///  3. Apps running right now without a window, usually living in the menu bar.
/// Only things that belong to an app become signals; loose system helpers are left alone.
struct LoginItemsScanner: SourceScanner {
    let source = DataSource.loginItems

    func scan() async -> ScanResult {
        var items: [Item] = []

        let loginApps = Self.loginItemApps()
        for url in loginApps.paths {
            if var item = Self.appItem(at: url) {
                item.signals.startsAtLogin = true
                items.append(item)
            }
        }
        for url in Self.launchAgentApps() {
            if var item = Self.appItem(at: url) {
                item.signals.startsAtLogin = true
                items.append(item)
            }
        }
        let background = await MainActor.run { Self.backgroundApps() }
        for (bundleID, name) in background {
            var item = Item(id: "app:\(bundleID)", name: name, kind: .app,
                            category: Categories.forApp(name: name, bundleID: bundleID))
            item.signals.runsInBackground = true
            items.append(item)
        }

        let combined = Scanners.combine(items)
        var summary = "\(combined.count) apps that start on their own or keep running in the background."
        if !loginApps.allowed { summary += " The login item list itself wasn't shared, so this may be incomplete." }
        return ScanResult(items: combined, report: SourceReport(source: source, readable: true, summary: summary))
    }

    /// Asks System Events for the login item list. `allowed` is false when the person said no.
    static func loginItemApps() -> (paths: [URL], allowed: Bool) {
        let script = "tell application \"System Events\" to get the path of every login item"
        guard let output = Shell.run("/usr/bin/osascript", ["-e", script], timeout: 30) else { return ([], false) }
        // osascript prints a list as "a, b, c". App paths don't contain ", " in practice.
        let paths = output.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: ", ")
            .filter { $0.hasSuffix(".app") || $0.hasSuffix(".app/") }
            .map { URL(fileURLWithPath: $0) }
        return (paths, true)
    }

    /// Launch agents that point into an app bundle, for this user and for all users.
    static func launchAgentApps() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let folders = [home.appendingPathComponent("Library/LaunchAgents"),
                       URL(fileURLWithPath: "/Library/LaunchAgents")]
        var apps: [URL] = []
        for folder in folders {
            let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
            for file in files where file.pathExtension == "plist" {
                guard let dict = NSDictionary(contentsOf: file) as? [String: Any] else { continue }
                // RunAtLoad false means it only starts when asked, so it isn't "always on".
                if let runs = dict["RunAtLoad"] as? Bool, runs == false, dict["KeepAlive"] == nil { continue }
                let program = (dict["Program"] as? String) ?? ((dict["ProgramArguments"] as? [String])?.first)
                if let program, let app = appBundle(containing: program) { apps.append(app) }
            }
        }
        return apps
    }

    /// "/Applications/Spotify.app/Contents/MacOS/Helper" -> "/Applications/Spotify.app".
    static func appBundle(containing path: String) -> URL? {
        guard let range = path.range(of: ".app/") ?? path.range(of: ".app", options: .backwards),
              path.hasPrefix("/Applications") || path.contains("/Applications/") else { return nil }
        return URL(fileURLWithPath: String(path[..<range.upperBound]).replacingOccurrences(of: ".app/", with: ".app"))
    }

    static func appItem(at url: URL) -> Item? {
        guard let bundleID = Bundle(url: url)?.bundleIdentifier, !AppsScanner.ignored.contains(bundleID) else { return nil }
        let name = url.deletingPathExtension().lastPathComponent
        return Item(id: "app:\(bundleID)", name: name, kind: .app,
                    category: Categories.forApp(name: name, bundleID: bundleID))
    }

    /// Running apps with no Dock icon: menu bar helpers and the like. Apple's own are part of macOS.
    @MainActor
    static func backgroundApps() -> [(String, String)] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .accessory,
                  let id = app.bundleIdentifier, !id.hasPrefix("com.apple."),
                  !AppsScanner.ignored.contains(id),
                  let url = app.bundleURL, url.path.hasPrefix("/Applications") else { return nil }
            return (id, app.localizedName ?? url.deletingPathExtension().lastPathComponent)
        }
    }
}
