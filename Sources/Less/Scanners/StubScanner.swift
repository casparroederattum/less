import Foundation

/// Made-up results, used when Less is started with --demo.
/// It was the first scanner written: the whole flow worked end to end on these
/// before any real system access existed. It stays useful for trying the screens.
struct StubScanner: SourceScanner {
    let source: DataSource

    func scan() async -> ScanResult {
        // A short pause so the progress screen can be seen. Only in demo mode.
        try? await Task.sleep(nanoseconds: 400_000_000)
        let monthsAgo = Date().addingTimeInterval(-200 * 86_400)

        func app(_ id: String, _ name: String, _ c: Category, _ change: (inout Signals) -> Void) -> Item {
            var item = Item(id: "app:\(id)", name: name, kind: .app, category: c)
            change(&item.signals)
            return item
        }

        let items: [Item]
        switch source {
        case .apps:
            items = [
                app("com.roblox.RobloxPlayer", "Roblox", .games) { $0.lastUsed = monthsAgo },
                app("com.apple.iMovieApp", "iMovie", .unknown) { $0.lastUsed = monthsAgo },
                app("com.spotify.client", "Spotify", .audio) { $0.lastUsed = Date() },
            ]
        case .screenTime:
            items = [
                app("com.spotify.client", "Spotify", .audio) { $0.minutesPerDay = 90; $0.opensPerDay = 4 },
                app("com.openai.chat", "ChatGPT", .aiAssistant) { $0.minutesPerDay = 40; $0.opensPerDay = 12 },
                app("com.hnc.Discord", "Discord", .social) { $0.minutesPerDay = 75; $0.opensPerDay = 35 },
            ]
        case .browsers:
            var insta = Item(id: "web:instagram.com", name: "instagram.com", kind: .website, category: .social)
            insta.signals.minutesPerDay = 120
            insta.signals.visitsPerDay = 160
            var yt = Item(id: "web:youtube.com", name: "youtube.com", kind: .website, category: .video)
            yt.signals.minutesPerDay = 55
            yt.signals.visitsPerDay = 30
            items = [insta, yt]
        case .loginItems:
            items = [app("com.spotify.client", "Spotify", .audio) { $0.runsInBackground = true }]
        case .notifications:
            items = [app("com.hnc.Discord", "Discord", .social) { $0.notificationsOn = true }]
        case .bluetooth:
            var band = Item(id: "device:WHOOP 4.0", name: "WHOOP 4.0", kind: .device, category: .quantifiedSelf)
            band.signals.connectedNow = true
            items = [band, Item(id: "device:AirPods", name: "AirPods", kind: .device, category: .audio)]
        case .localNetwork:
            var tv = Item(id: "device:net:Living Room", name: "Living Room", kind: .device, category: .video)
            tv.signals.onHomeNetwork = true
            items = [tv]
        }
        return ScanResult(items: items, report: SourceReport(
            source: source, readable: true, summary: "Made-up example data (demo mode)."))
    }
}
