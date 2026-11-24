import Foundation

enum Verdict: String, Codable, CaseIterable {
    case letGo, reduce, keep

    var title: String {
        switch self {
        case .letGo: return "Let go"
        case .reduce: return "Reduce"
        case .keep: return "Keep"
        }
    }
}

/// What a thing tends to replace in a life. The weight is how hard it leans toward
/// "Reduce" or "Let go". Things that stand in for people, movement or your own
/// thinking get 2; things that mostly fill time get 1; plain tools get 0.
enum Category: String, Codable {
    case social, delivery, quantifiedSelf, aiAssistant, indoorTraining, phone
    case video, games, shopping, news, smartHome
    case messaging, audio, tools, unknown

    var weight: Int {
        switch self {
        case .social, .delivery, .quantifiedSelf, .aiAssistant, .indoorTraining, .phone: return 2
        case .video, .games, .shopping, .news, .smartHome: return 1
        case .messaging, .audio, .tools, .unknown: return 0
        }
    }

    /// Neutral things count time at half weight: two hours of music while you cook is not a problem.
    var isNeutral: Bool { weight == 0 }
}

enum ItemKind: String, Codable {
    case app, website, device, added
}

/// The few numbers a verdict is built on. Everything is optional because every
/// source is optional. Only totals and counts, never content.
struct Signals: Codable, Equatable {
    var minutesPerDay: Double?
    var opensPerDay: Double?
    var visitsPerDay: Double?
    var lastUsed: Date?
    var startsAtLogin = false
    var runsInBackground = false
    var notificationsOn: Bool?
    var connectedNow = false
    var onHomeNetwork = false

    /// Two scanners can see the same app. Keep whatever each one knows.
    mutating func merge(_ other: Signals) {
        minutesPerDay = Signals.larger(minutesPerDay, other.minutesPerDay)
        opensPerDay = Signals.larger(opensPerDay, other.opensPerDay)
        visitsPerDay = Signals.larger(visitsPerDay, other.visitsPerDay)
        if let d = other.lastUsed, d > (lastUsed ?? .distantPast) { lastUsed = d }
        startsAtLogin = startsAtLogin || other.startsAtLogin
        runsInBackground = runsInBackground || other.runsInBackground
        if let n = other.notificationsOn { notificationsOn = (notificationsOn ?? false) || n }
        connectedNow = connectedNow || other.connectedNow
        onHomeNetwork = onHomeNetwork || other.onHomeNetwork
    }

    /// The bigger of two numbers that might be missing. Missing never wins over a real number.
    static func larger(_ a: Double?, _ b: Double?) -> Double? {
        guard let a else { return b }
        guard let b else { return a }
        return max(a, b)
    }
}

struct Item: Codable, Identifiable, Equatable {
    /// Stable across scans ("app:com.spotify.client", "web:youtube.com"), so "Done" survives a re-scan.
    var id: String
    var name: String
    var kind: ItemKind
    var category: Category
    var signals = Signals()

    var verdict: Verdict = .keep
    var why = ""
    var instead = ""
    var done = false

    /// The line under each card, so the verdict never hides what it rests on.
    var basedOn: String {
        var parts: [String] = []
        if let m = signals.minutesPerDay, m >= 1 { parts.append("\(Format.duration(minutes: m)) a day") }
        if let o = signals.opensPerDay, o >= 1 { parts.append("opened \(Int(o.rounded())) times a day") }
        if let v = signals.visitsPerDay, v >= 1 { parts.append("visited \(Int(v.rounded())) times a day") }
        if let d = signals.lastUsed { parts.append("last opened \(Format.day(d))") }
        if signals.startsAtLogin { parts.append("opens at login") }
        if signals.runsInBackground { parts.append("runs in the background") }
        if signals.notificationsOn == true { parts.append("notifications on") }
        if signals.connectedNow { parts.append("connected now") }
        if kind == .device && !signals.connectedNow && !signals.onHomeNetwork { parts.append("paired with this Mac") }
        if signals.onHomeNetwork { parts.append("on your home network") }
        if kind == .added { parts.append("you added this yourself") }
        return parts.isEmpty ? "Based on: very little, so take this lightly" : "Based on: " + parts.joined(separator: " · ")
    }
}

enum Format {
    /// 190 -> "3h 10m", 40 -> "40 min". Rounded to five minutes above an hour, because more precision would be false.
    static func duration(minutes: Double) -> String {
        let m = Int(minutes.rounded())
        if m < 60 { return "\(max(m, 1)) min" }
        let rounded = (m + 2) / 5 * 5
        let h = rounded / 60, rest = rounded % 60
        return rest == 0 ? "\(h)h" : "\(h)h \(rest)m"
    }

    /// "12 March", or "12 March 2024" when it isn't this year.
    static func day(_ date: Date) -> String {
        let sameYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = sameYear ? "d MMMM" : "d MMMM yyyy"
        return f.string(from: date)
    }

    /// "March", or "March 2024" when it isn't this year.
    static func month(_ date: Date) -> String {
        let sameYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = sameYear ? "MMMM" : "MMMM yyyy"
        return f.string(from: date)
    }
}
