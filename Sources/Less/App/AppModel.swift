import SwiftUI

enum Page: Hashable { case scan, why }

enum Stage: Equatable {
    case welcome
    case permission(Int)   // index into DataSource.allCases
    case scanning
    case results
}

/// The one place app state lives. Views read from it and call its methods; nothing else changes state.
@MainActor
final class AppModel: ObservableObject {
    @Published var page: Page = .scan
    @Published var stage: Stage = .welcome
    @Published var saved: SavedState
    @Published var progress: [DataSource] = []      // sources finished so far in this scan
    @Published var current: String = ""             // what is being looked at right now

    /// Started with --demo: made-up data, so the screens can be tried without any permissions.
    let demo: Bool

    init() {
        demo = CommandLine.arguments.contains("--demo")
        // Demo mode never touches the real file, so trying the screens can't overwrite a real scan.
        saved = demo ? SavedState() : Store.load()
        if saved.lastScan != nil { stage = .results }
    }

    // MARK: Flow

    func start() {
        withAnimation(.easeInOut(duration: 0.3)) { stage = .permission(0) }
    }

    func choose(_ source: DataSource, allowed: Bool) {
        saved.choices[source.rawValue] = allowed
        persist()
        if allowed {
            // Ask macOS its own question right now, next to the card that explains it.
            switch source {
            case .bluetooth: Permissions.askForBluetooth()
            case .localNetwork: Task { await NetworkDevicesScanner.askOnce() }
            default: break
            }
        }
        let next = (DataSource.allCases.firstIndex(of: source) ?? 0) + 1
        withAnimation(.easeInOut(duration: 0.3)) {
            stage = next < DataSource.allCases.count ? .permission(next) : .scanning
        }
        if stage == .scanning { Task { await runScan() } }
    }

    func isAllowed(_ source: DataSource) -> Bool { saved.choices[source.rawValue] == true }

    func rescan() {
        withAnimation(.easeInOut(duration: 0.3)) { stage = .scanning }
        Task { await runScan() }
    }

    /// Lets the person look at the permission cards again, to change an earlier choice.
    func reviewPermissions() {
        withAnimation(.easeInOut(duration: 0.3)) { stage = .permission(0) }
    }

    // MARK: The scan

    func runScan() async {
        progress = []
        var found: [Item] = []
        var reports: [SourceReport] = []

        for scanner in Scanners.all(demo: demo) where isAllowed(scanner.source) || demo {
            current = scanner.source.progressText
            let result = await scanner.scan()
            found += result.items
            reports.append(result.report)
            progress.append(scanner.source)
        }

        current = "Putting it together"
        var items = Scanners.combine(found) + saved.added
        let before = saved.lastScan
        let doneBefore = Set((before?.items ?? []).filter(\.done).map(\.id))

        for i in items.indices {
            let (verdict, reason) = VerdictRules.decide(items[i])
            items[i].verdict = verdict
            items[i].why = Phrases.why(items[i], verdict, reason)
            items[i].instead = Phrases.instead(items[i], verdict, reason)
            items[i].done = doneBefore.contains(items[i].id) && verdict != .keep
        }

        let shown = items.filter(VerdictRules.deservesCard)
        let quiet = items.count - shown.count
        var ordered = shown.sorted(by: Self.order)

        // Optional local wording. Only for cards that suggest a change, and only a handful, so it stays quick.
        if let model = await LocalWords.availableModel() {
            current = "Choosing the words"
            for i in ordered.indices where ordered[i].verdict != .keep && i < 12 {
                let words = await LocalWords.rephrase(ordered[i], model: model)
                ordered[i].why = words.why
                ordered[i].instead = words.instead
            }
        }

        if before != nil { saved.previousScan = before }
        saved.lastScan = ScanRecord(date: Date(), items: ordered, quietCount: quiet)
        saved.reports = reports
        persist()
        withAnimation(.easeInOut(duration: 0.4)) { stage = .results }
    }

    /// Let go first, then Reduce, then Keep. Within each, the thing with the most time first.
    static func order(_ a: Item, _ b: Item) -> Bool {
        let rank: [Verdict: Int] = [.letGo: 0, .reduce: 1, .keep: 2]
        if a.verdict != b.verdict { return rank[a.verdict]! < rank[b.verdict]! }
        return (a.signals.minutesPerDay ?? 0) > (b.signals.minutesPerDay ?? 0)
    }

    // MARK: Changes the person makes

    func toggleDone(_ id: String) {
        guard var scan = saved.lastScan, let i = scan.items.firstIndex(where: { $0.id == id }) else { return }
        scan.items[i].done.toggle()
        saved.lastScan = scan
        persist()
    }

    /// Adds or removes one of the "Fill the gaps" suggestions. The verdict is worked out
    /// with the same rules as everything else.
    func toggleAdded(_ suggestion: GapSuggestion) {
        guard var scan = saved.lastScan else { return }
        if let i = saved.added.firstIndex(where: { $0.id == suggestion.id }) {
            saved.added.remove(at: i)
            scan.items.removeAll { $0.id == suggestion.id }
        } else {
            var item = Item(id: suggestion.id, name: suggestion.name, kind: .added, category: suggestion.category)
            let (verdict, reason) = VerdictRules.decide(item)
            item.verdict = verdict
            item.why = Phrases.why(item, verdict, reason)
            item.instead = Phrases.instead(item, verdict, reason)
            saved.added.append(item)
            scan.items.append(item)
            scan.items.sort(by: Self.order)
        }
        withAnimation(.easeInOut(duration: 0.25)) { saved.lastScan = scan }
        persist()
    }

    func isAdded(_ suggestion: GapSuggestion) -> Bool {
        saved.added.contains { $0.id == suggestion.id }
    }

    /// Wipes the file and starts over, as if Less had just been installed.
    func deleteEverything() {
        Store.wipe()
        saved = SavedState()
        progress = []
        withAnimation(.easeInOut(duration: 0.3)) {
            page = .scan
            stage = .welcome
        }
    }

    private func persist() {
        if !demo { Store.save(saved) }
    }
}

/// Things a Mac can't see. One tap adds them to the results.
struct GapSuggestion: Identifiable {
    var id: String
    var name: String
    var category: Category

    static let all: [GapSuggestion] = [
        GapSuggestion(id: "added:iphone", name: "My iPhone", category: .phone),
        GapSuggestion(id: "added:band", name: "A fitness band or watch", category: .quantifiedSelf),
        GapSuggestion(id: "added:delivery", name: "Food or grocery delivery", category: .delivery),
        GapSuggestion(id: "added:trainer", name: "An indoor bike trainer", category: .indoorTraining),
        GapSuggestion(id: "added:streaming", name: "A streaming subscription", category: .video),
        GapSuggestion(id: "added:speaker", name: "A speaker you talk to", category: .smartHome),
    ]
}
