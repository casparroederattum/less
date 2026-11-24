import Foundation

/// Optional: if Ollama is running on this Mac, a small local language model rewrites the
/// two sentences on a card so they read a little more personally.
///
/// It never decides anything. The verdict is already fixed by VerdictRules; the model only
/// rewords. Every answer is checked against the same language rules as the built-in sentences,
/// and anything that fails is thrown away in favour of the built-in one. If Ollama isn't
/// there, nothing changes at all. The address is 127.0.0.1: this Mac, never the internet.
enum LocalWords {
    static let base = URL(string: "http://127.0.0.1:11434")!
    static let preferredModel = "llama3.2:3b"

    /// Returns a model name if Ollama answers within a second, otherwise nil.
    static func availableModel() async -> String? {
        var request = URLRequest(url: base.appendingPathComponent("api/tags"))
        request.timeoutInterval = 1
        guard let reply = try? await session.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: reply.0) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else { return nil }
        let names = models.compactMap { $0["name"] as? String }
        return names.first { $0 == preferredModel }
            ?? names.first { $0.hasPrefix("llama3.2") }
            ?? names.first
    }

    /// Rewrites why/instead for one item. Each sentence is kept only if it passes the rules.
    static func rephrase(_ item: Item, model: String) async -> (why: String, instead: String) {
        let prompt = """
            Thing: \(item.name)
            What we know: \(item.basedOn.replacingOccurrences(of: "Based on: ", with: ""))
            Verdict: \(item.verdict.title)
            Reason now: \(item.why)
            Suggestion now: \(item.instead)

            Rewrite the reason and the suggestion. Keep the same meaning and the same facts.
            Answer with exactly two lines: the reason on the first, the suggestion on the second.
            """
        let body: [String: Any] = [
            "model": model, "system": rules, "prompt": prompt, "stream": false,
            "options": ["temperature": 0.4, "num_predict": 80],
        ]
        var request = URLRequest(url: base.appendingPathComponent("api/generate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20

        guard let reply = try? await session.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: reply.0) as? [String: Any],
              let text = json["response"] as? String else { return (item.why, item.instead) }

        let lines = text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"-*•1234567890.)")) }
            .filter { !$0.isEmpty }
        let why = lines.count == 2 && Words.isClean(lines[0]) ? finished(lines[0]) : item.why
        let instead = lines.count == 2 && Words.isClean(lines[1]) ? finished(lines[1]) : item.instead
        return (why, instead)
    }

    /// The same rules a person writing for Less would follow.
    static let rules = """
        You write short sentences for a calm app that helps people use less technology.
        Write like a thoughtful friend, plainly, like a well-made book.
        Each sentence: one fact plus one human reason, or one small concrete thing to do this week.
        At most 20 words per sentence. One sentence per line.
        Never use the words: AI, smart, intelligent, analyzing, insights, personalized, recommendations,
        powered by, optimize, leverage, unlock, seamless, journey, empower, should.
        Never say "I". No exclamation marks. No emoji. No guilt, no lecturing.
        Keeping something is a perfectly good answer.
        """

    /// Trimming above strips trailing full stops along with list markers; put one back.
    private static func finished(_ s: String) -> String {
        s.hasSuffix(".") || s.hasSuffix("?") ? s : s + "."
    }

    /// A session that never caches and never waits for a network that isn't there.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()
}
