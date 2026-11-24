import Foundation

/// The pre-written sentences. Every card works with these alone.
/// Shape of "why": one fact, then one human reason. Shape of "instead": one small thing to do this week.
enum Phrases {

    static func why(_ item: Item, _ verdict: Verdict, _ reason: VerdictRules.Reason) -> String {
        let f = fact(item, reason)
        if reason == .unused { return "\(f). It's only taking up space." }
        if verdict == .keep { return "\(f). \(keepLine(item.category))" }
        return "\(f), \(humanReason(item.category, reason))."
    }

    static func instead(_ item: Item, _ verdict: Verdict, _ reason: VerdictRules.Reason) -> String {
        if verdict == .keep { return "Nothing to change." }
        if reason == .unused { return "Move it to the Trash. You can always get it back." }

        // For neutral things the habit around them is the issue, not the thing itself.
        if item.category.isNeutral {
            switch reason {
            case .notifications: return "Turn its notifications off for a week and see what you miss."
            case .background: return "Turn off Open at Login, and start it only when you need it."
            default: break
            }
        }
        // A website can't be put in the Trash or start at login, so plain sites get their own pair.
        let plainSite = item.kind == .website && item.category.isNeutral
        let pair = plainSite ? websitePair : (alternatives[item.category] ?? websitePair)
        return verdict == .letGo ? pair.letGo : pair.reduce
    }

    // MARK: Pieces

    /// The one fact a verdict rests on, written the way a friend would say it.
    private static func fact(_ item: Item, _ reason: VerdictRules.Reason) -> String {
        let s = item.signals
        switch reason {
        case .unused:
            if let d = s.lastUsed { return "You haven't opened it since \(Format.month(d))" }
        case .time:
            if let m = s.minutesPerDay { return "You spend about \(Format.duration(minutes: m)) a day on it" }
        case .opens:
            if let o = s.opensPerDay, o >= 1 { return "You open it about \(Int(o.rounded())) times a day" }
            if let v = s.visitsPerDay { return "You visit it about \(Int(v.rounded())) times a day" }
        case .notifications:
            return "It's allowed to interrupt you"
        case .background:
            return s.startsAtLogin ? "It opens with your Mac and stays open" : "It keeps running in the background"
        case .device:
            if s.onHomeNetwork { return "It's on your home network, always on" }
            if s.connectedNow { return "It's connected right now" }
        case .added:
            return "You added it yourself"
        case .light:
            break
        }
        if item.kind == .device { return "It's paired with this Mac" }
        if let m = s.minutesPerDay, m >= 1 { return "You spend about \(Format.duration(minutes: m)) a day on it" }
        return "You use it now and then"
    }

    private static func humanReason(_ c: Category, _ reason: VerdictRules.Reason) -> String {
        switch c {
        case .social: return "and most of it is strangers, not friends"
        case .video: return "and it tends to decide what comes next"
        case .games: return "and evenings have a way of disappearing into it"
        case .shopping: return "and looking quietly turns into buying"
        case .delivery: return "and the walk to the shop was doing you good"
        case .quantifiedSelf: return "and the numbers start telling you how you feel"
        case .aiAssistant: return "and some of that thinking is worth doing yourself"
        case .indoorTraining: return "and the road outside has weather, people and hills"
        case .phone: return "and it's the one thing that is always within reach"
        case .news: return "and most of it changes nothing about your day"
        case .smartHome: return "and it waits in the room even when nobody needs it"
        case .messaging: return "and every message starts to feel urgent"
        case .audio: return "and a little quiet now and then does you good"
        case .tools, .unknown:
            return reason == .background ? "even on days you don't need it" : "and it may need you more than you need it"
        }
    }

    private static func keepLine(_ c: Category) -> String {
        switch c {
        case .audio: return "Music and podcasts can keep you company without taking over."
        case .messaging: return "It mostly connects you with people you know."
        case .tools, .unknown: return "It does its job and gets out of the way."
        default: return "You use it lightly, and that seems fine."
        }
    }

    private static let websitePair = (letGo: "Remove it from your bookmarks and let it fade.",
                                      reduce: "Close the tab when you're done instead of leaving it open.")

    private static let alternatives: [Category: (letGo: String, reduce: String)] = [
        .social: ("Call one friend on Sunday instead of scrolling.",
                  "Move it off your Dock and check it once, in the evening."),
        .video: ("Pick one film for Friday night and close the tab after.",
                 "Watch with someone else, not alone before sleep."),
        .games: ("Play a board game with your flatmates this week.",
                 "Keep it for the weekend, and play with friends when you can."),
        .shopping: ("Write what you need on paper and buy it in town on Saturday.",
                    "Leave things in the basket for two days before you buy."),
        .delivery: ("Walk to the market on Saturday instead of ordering.",
                    "Order once a week at most, and walk for the rest."),
        .quantifiedSelf: ("Leave it in a drawer for a week and notice how you feel.",
                          "Look at the numbers once a week, not every morning."),
        .aiAssistant: ("Do your next problem sheet on paper first.",
                       "Try the task on paper for twenty minutes before asking for help."),
        .indoorTraining: ("Ride outside this weekend, even if it's grey.",
                          "Keep it for rainy days and ride outside when it's dry."),
        .phone: ("Leave it in another room for one evening this week.",
                 "Keep it out of the bedroom and use a paper alarm clock."),
        .news: ("Read one paper on Sunday instead of checking every day.",
                "Check the news once a day, after lunch."),
        .smartHome: ("Unplug it for a weekend and see if you miss it.",
                     "Unplug it at night and plug it in when you want it."),
        .messaging: ("Tell people they can call you, and close it for a day.",
                     "Turn off notifications and reply twice a day."),
        .audio: ("Leave your headphones at home on your next walk.",
                 "Take one walk this week without anything in your ears."),
        .tools: ("Move it to the Trash. You can always get it back.",
                 "Turn off Open at Login, and start it only when you need it."),
        .unknown: ("Move it to the Trash. You can always get it back.",
                   "Turn off Open at Login, and start it only when you need it."),
    ]
}
