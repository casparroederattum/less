import Foundation
import Network

/// Speakers, TVs and hubs that announce themselves on the home network (Bonjour).
/// We listen for a few seconds and keep only names. Nothing is sent to them.
struct NetworkDevicesScanner: SourceScanner {
    let source = DataSource.localNetwork
    static let listenSeconds: UInt64 = 5

    /// The kinds of announcements we listen for, and what they usually are.
    /// Every type here must also be listed under NSBonjourServices in Info.plist, or macOS blocks it.
    static let kinds: [(type: String, category: Category)] = [
        ("_googlecast._tcp", .video),          // Chromecast, Google TV, many TVs
        ("_airplay._tcp", .video),             // Apple TV, AirPlay TVs
        ("_amzn-wplay._tcp", .video),          // Fire TV
        ("_raop._tcp", .smartHome),            // AirPlay speakers
        ("_spotify-connect._tcp", .smartHome), // Spotify speakers
        ("_sonos._tcp", .smartHome),
        ("_hap._tcp", .smartHome),             // HomeKit accessories
        ("_homekit._tcp", .smartHome),
    ]

    func scan() async -> ScanResult {
        let found = await Self.listen(seconds: Self.listenSeconds)
        let items = found.map { name, category -> Item in
            var item = Item(id: "device:net:\(name)", name: name, kind: .device, category: category)
            item.signals.onHomeNetwork = true
            return item
        }.sorted { $0.name < $1.name }

        let summary = items.isEmpty
            ? "Nothing announced itself on your network, or the permission wasn't given."
            : "Names of \(items.count) speakers, screens or hubs on your home network."
        return ScanResult(items: items, report: SourceReport(source: source, readable: true, summary: summary))
    }

    /// Browses all kinds at once, waits, then stops. Returns cleaned name -> category.
    static func listen(seconds: UInt64) async -> [String: Category] {
        let queue = DispatchQueue(label: "less.bonjour")   // one queue, so the dictionary is never touched twice at once
        let found = Found()
        let own = Host.current().localizedName ?? ""

        let browsers = kinds.map { kind -> NWBrowser in
            let browser = NWBrowser(for: .bonjour(type: kind.type, domain: nil), using: .tcp)
            browser.browseResultsChangedHandler = { results, _ in
                for result in results {
                    guard case let .service(name, _, _, _) = result.endpoint else { continue }
                    let clean = Self.cleanName(name)
                    guard !clean.isEmpty, clean != own, !Self.isPersonalComputer(clean) else { continue }
                    // Keep the first kind we heard for a device: a TV also announces itself as a speaker.
                    if found.names[clean] == nil { found.names[clean] = kind.category }
                }
            }
            browser.start(queue: queue)
            return browser
        }

        try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
        return queue.sync {
            browsers.forEach { $0.cancel() }
            return found.names
        }
    }

    /// A small box the browsers write into. Only ever touched on `queue`.
    private final class Found {
        var names: [String: Category] = [:]
    }

    /// AirPlay speakers announce as "A1B2C3D4E5F6@Kitchen". People only know "Kitchen".
    static func cleanName(_ name: String) -> String {
        guard let at = name.firstIndex(of: "@") else { return name }
        return String(name[name.index(after: at)...])
    }

    /// Macs, iPhones and iPads also announce AirPlay. They belong to people, often flatmates,
    /// and aren't home devices. Leaving them out is both more accurate and more polite.
    static func isPersonalComputer(_ name: String) -> Bool {
        let lower = name.lowercased()
        return ["macbook", "imac", "mac mini", "mac studio", "iphone", "ipad"].contains { lower.contains($0) }
    }

    /// Called from the permission card, so macOS shows its Local Network question right then,
    /// in context, rather than in the middle of the scan.
    static func askOnce() async {
        _ = await listen(seconds: 2)
    }
}
