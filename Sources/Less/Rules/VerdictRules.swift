import Foundation

/// The whole verdict logic. No model, no network: a handful of points you can add up by hand.
///
/// Worked example, traced before this was written:
///   Instagram in Safari: about 2h a day, opened ~80 times a day, notifications on, social.
///     time   120 min/day  -> +3
///     opens   80 per day  -> +2
///     notifications on    -> +1
///     category social     -> +2   (stands in for real contact)
///     total 8  -> 6 or more is "Let go".
///   Spotify: 90 min/day, runs in the background, audio.
///     time 90 min -> +2, halved for a neutral category -> +1
///     background  -> +1
///     total 2  -> below 3 is "Keep". Music while cooking is fine.
enum VerdictRules {

    static let letGoAt = 6
    static let reduceAt = 3
    /// Three months untouched is long enough to say "you won't miss it".
    static let unusedDays = 90

    /// The one signal that matters most for this item. Phrases uses it to say *why* in one fact.
    enum Reason: String {
        case unused, time, opens, notifications, background, device, added, light
    }

    static func decide(_ item: Item) -> (Verdict, Reason) {
        if isUnused(item) { return (.letGo, .unused) }

        let parts = points(item)
        let total = parts.reduce(0) { $0 + $1.points } + item.category.weight
        let verdict: Verdict = total >= letGoAt ? .letGo : total >= reduceAt ? .reduce : .keep

        // The biggest contributor becomes the fact we show. Ties go to the earlier, more concrete one.
        let strongest = parts.filter { $0.points > 0 }.max { $0.points < $1.points }
        return (verdict, strongest?.reason ?? fallbackReason(item))
    }

    /// Each signal turned into points, kept separate so we can tell which one weighed most.
    static func points(_ item: Item) -> [(reason: Reason, points: Int)] {
        let s = item.signals
        // Neutral things (music, messages, tools) count usage at half: using them a lot isn't the problem.
        let halve: (Int) -> Int = { item.category.isNeutral ? $0 / 2 : $0 }

        let minutes = s.minutesPerDay ?? 0
        let time = minutes >= 120 ? 3 : minutes >= 60 ? 2 : minutes >= 30 ? 1 : 0

        // App opens and page visits are different animals: one page view is not one pick-up.
        let opens = s.opensPerDay ?? 0
        let visits = s.visitsPerDay ?? 0
        let reach = opens >= 50 || visits >= 100 ? 2 : opens >= 20 || visits >= 40 ? 1 : 0

        let alwaysOn = s.startsAtLogin || s.runsInBackground

        return [
            (.time, halve(time)),
            (.opens, halve(reach)),
            (.notifications, s.notificationsOn == true ? 1 : 0),
            (.background, alwaysOn ? 1 : 0),
            (.device, item.kind == .device && (s.connectedNow || s.onHomeNetwork) ? 1 : 0),
            // Adding something by hand means it's on your mind. That alone is worth one point.
            (.added, item.kind == .added ? 1 : 0),
        ]
    }

    static func isUnused(_ item: Item) -> Bool {
        guard item.kind == .app, let last = item.signals.lastUsed else { return false }
        let days = Date().timeIntervalSince(last) / 86_400
        return days > Double(unusedDays) && (item.signals.minutesPerDay ?? 0) < 5
    }

    private static func fallbackReason(_ item: Item) -> Reason {
        switch item.kind {
        case .device: return .device
        case .added: return .added
        default: return .light
        }
    }

    /// Only things worth a card get one. A recently used plain tool is fine and stays quiet,
    /// otherwise the results would be forty cards long and nobody would read them.
    static func deservesCard(_ item: Item) -> Bool {
        if item.kind != .app { return true }
        if item.verdict != .keep { return true }
        if item.category.weight > 0 { return true }
        return (item.signals.minutesPerDay ?? 0) >= 30
    }
}
