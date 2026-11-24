import Foundation

/// Decides what kind of thing an app, website or device is.
/// Plain lookup tables, so anyone can read why something was put where it is.
enum Categories {

    // MARK: Apps and devices, by words in their name or bundle id

    /// Checked in order; the first match wins. Order matters where words overlap.
    private static let keywords: [(Category, [String])] = [
        (.aiAssistant, ["chatgpt", "openai", "claude", "anthropic", "perplexity", "copilot", "gemini", "deepseek"]),
        (.indoorTraining, ["zwift", "rouvy", "tacx", "kickr", "trainerroad"]),
        (.quantifiedSelf, ["whoop", "oura", "garmin", "fitbit", "polar", "strava", "amazfit", "coros", "suunto", "watch"]),
        (.delivery, ["lieferando", "wolt", "ubereats", "uber eats", "flink", "gorillas", "getir", "picnic", "hellofresh", "deliveroo", "doordash", "knuspr"]),
        (.social, ["instagram", "tiktok", "facebook", "twitter", "reddit", "discord", "snapchat", "bereal", "threads", "pinterest", "linkedin", "bluesky", "tweetie"]),
        (.video, ["netflix", "disney", "primevideo", "prime video", "youtube", "twitch", "joyn", "com.apple.tv"]),
        (.games, ["roblox", "minecraft", "mojang", "steam", "epicgames", "epic games", "blizzard", "battle.net", "riotgames", "league of legends", "fortnite"]),
        (.shopping, ["amazon", "zalando", "ebay", "temu", "shein", "aliexpress", "vinted"]),
        (.news, ["com.apple.news", "spiegel", "tagesschau"]),
        (.phone, ["iphone", "ipad"]),
        (.audio, ["spotify", "com.apple.music", "podcasts", "soundcloud", "tidal", "deezer", "airpods", "beats", "bose", "jbl", "sennheiser", "headphone", "earbuds", "buds"]),
        (.smartHome, ["homepod", "echo", "sonos", "alexa", "nest", "speaker"]),
        (.messaging, ["whatsapp", "telegram", "signal", "mobilesms", "messages", "slack", "teams", "zoom", "facetime", "messenger"]),
    ]

    static func forApp(name: String, bundleID: String) -> Category {
        match("\(name) \(bundleID)")
    }

    static func forDevice(name: String) -> Category {
        let lower = name.lowercased()
        // Input devices are part of using a computer, not a habit. They never get a card.
        if ["keyboard", "mouse", "trackpad"].contains(where: { lower.contains($0) }) { return .tools }
        return match(lower)
    }

    private static func match(_ text: String) -> Category {
        let lower = text.lowercased()
        for (category, words) in keywords where words.contains(where: { lower.contains($0) }) {
            return category
        }
        return .unknown
    }

    // MARK: Websites

    private static let domains: [String: Category] = [
        // social
        "instagram.com": .social, "tiktok.com": .social, "facebook.com": .social, "x.com": .social,
        "twitter.com": .social, "reddit.com": .social, "linkedin.com": .social, "snapchat.com": .social,
        "threads.net": .social, "pinterest.com": .social, "bsky.app": .social, "tumblr.com": .social,
        "9gag.com": .social, "discord.com": .social,
        // video
        "youtube.com": .video, "netflix.com": .video, "twitch.tv": .video, "disneyplus.com": .video,
        "primevideo.com": .video, "joyn.de": .video,
        // messaging
        "web.whatsapp.com": .messaging, "messenger.com": .messaging, "web.telegram.org": .messaging,
        // shopping
        "amazon.de": .shopping, "amazon.com": .shopping, "zalando.de": .shopping, "ebay.de": .shopping,
        "ebay.com": .shopping, "temu.com": .shopping, "shein.com": .shopping, "aliexpress.com": .shopping,
        "otto.de": .shopping, "vinted.de": .shopping, "etsy.com": .shopping,
        // delivery
        "lieferando.de": .delivery, "wolt.com": .delivery, "ubereats.com": .delivery, "flink.com": .delivery,
        "getir.com": .delivery, "picnic.app": .delivery, "hellofresh.de": .delivery, "knuspr.de": .delivery,
        "deliveroo.com": .delivery,
        // thinking handed over
        "chatgpt.com": .aiAssistant, "chat.openai.com": .aiAssistant, "claude.ai": .aiAssistant,
        "gemini.google.com": .aiAssistant, "perplexity.ai": .aiAssistant, "copilot.microsoft.com": .aiAssistant,
        "chat.deepseek.com": .aiAssistant, "poe.com": .aiAssistant,
        // news
        "spiegel.de": .news, "bild.de": .news, "zeit.de": .news, "tagesschau.de": .news, "faz.net": .news,
        "sueddeutsche.de": .news, "welt.de": .news, "n-tv.de": .news, "t-online.de": .news, "focus.de": .news,
        "nytimes.com": .news, "theguardian.com": .news, "bbc.com": .news, "bbc.co.uk": .news,
        "news.ycombinator.com": .news,
        // games
        "chess.com": .games, "poki.com": .games, "crazygames.com": .games,
        // body numbers
        "whoop.com": .quantifiedSelf, "strava.com": .quantifiedSelf, "connect.garmin.com": .quantifiedSelf,
        "zwift.com": .indoorTraining,
    ]

    /// Turns a host into the name a person would use, and its category.
    /// "m.youtube.com" -> ("youtube.com", .video). "gemini.google.com" stays itself,
    /// because google.com as a whole would wrongly include every search.
    static func forHost(_ rawHost: String) -> (key: String, category: Category) {
        let host = rawHost.lowercased()
        var best: (key: String, category: Category)?
        for (key, category) in domains where host == key || host.hasSuffix("." + key) {
            if key.count > (best?.key.count ?? 0) { best = (key, category) }
        }
        if let best { return best }
        return (siteName(host), .unknown)
    }

    /// "www.uni-heilbronn.de" -> "uni-heilbronn.de", "news.bbc.co.uk" -> "bbc.co.uk".
    static func siteName(_ host: String) -> String {
        let labels = host.split(separator: ".").map(String.init)
        guard labels.count > 2 else { return host }
        let secondLast = labels[labels.count - 2]
        let keep = ["co", "com", "org", "net", "ac", "gov"].contains(secondLast) ? 3 : 2
        return labels.suffix(keep).joined(separator: ".")
    }
}
