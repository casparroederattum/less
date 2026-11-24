import Foundation

/// The language rules, written down once so the optional local model is held to
/// the same standard as the pre-written sentences.
enum Words {

    static let banned = [
        "ai", "a.i.", "artificial", "smart", "intelligent", "intelligence", "analyze", "analyzing", "analyse",
        "analysing", "analysis", "insight", "insights", "personalized", "personalised", "recommendation",
        "powered", "optimize", "optimise", "leverage", "unlock", "seamless", "journey", "empower",
        "great question", "digital wellbeing", "screen time", "mindful", "detox", "should",
    ]

    static let maxWords = 20

    /// True when a sentence could have been written by a thoughtful person:
    /// short, no banned words, no exclamation marks, no emoji, never "I".
    static func isClean(_ sentence: String) -> Bool {
        let s = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, !s.contains("!"), !s.contains("\n") else { return false }

        let words = s.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'.")).inverted)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            .filter { !$0.isEmpty }
        guard words.count <= maxWords else { return false }
        if words.contains("i") || words.contains("i'm") || words.contains("i've") { return false }

        let lower = s.lowercased()
        for word in banned {
            // Multi-word phrases are matched as text; single words only as whole words,
            // so "said" doesn't trip on "ai".
            if word.contains(" ") ? lower.contains(word) : words.contains(word) { return false }
        }

        // Emoji: anything drawn as a picture rather than a letter.
        let hasEmoji = s.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.value >= 0x1F000 }
        return !hasEmoji
    }
}
