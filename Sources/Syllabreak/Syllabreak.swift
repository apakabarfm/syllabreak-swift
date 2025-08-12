import Foundation

public final class Syllabreak: Sendable {
    public static let defaultSoftHyphen = "\u{00AD}"
    private let softHyphen: String
    private let metaRule: MetaRule

    struct RulesData: Codable {
        let rules: [LanguageRule]
    }

    public init(softHyphen: String = defaultSoftHyphen) {
        self.softHyphen = softHyphen
        self.metaRule = Syllabreak.loadRules()
    }

    private static func loadRules() -> MetaRule {
        guard let url = Bundle.module.url(forResource: "rules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rulesData = try? JSONDecoder().decode(RulesData.self, from: data) else {
            // Return empty MetaRule if can't load
            return MetaRule(rules: [])
        }
        return MetaRule(rules: rulesData.rules)
    }

    public func detectLanguage(_ text: String) -> [String] {
        let matchingRules = metaRule.findMatches(text)
        return matchingRules.map { $0.lang }
    }

    private func autoDetectRule(_ text: String) -> LanguageRule? {
        let matchingRules = metaRule.findMatches(text)
        return matchingRules.first
    }

    private func getRuleByLang(_ lang: String) -> LanguageRule? {
        for rule in metaRule.rules {
            if rule.lang == lang {
                return rule
            }
        }
        return nil
    }

    public func syllabify(_ text: String, lang: String? = nil) -> String {
        if text.isEmpty {
            return text
        }

        let rule: LanguageRule?
        if let lang = lang {
            guard let foundRule = getRuleByLang(lang) else {
                // Language not supported, return unchanged
                return text
            }
            rule = foundRule
        } else {
            rule = autoDetectRule(text)
            if rule == nil {
                return text
            }
        }

        guard let rule = rule else {
            return text
        }

        // Process each word
        var result: [String] = []
        var i = 0
        let chars = Array(text)

        while i < chars.count {
            // Find word boundaries
            if !chars[i].isLetter {
                result.append(String(chars[i]))
                i += 1
                continue
            }

            // Found start of word
            let wordStart = i
            while i < chars.count && chars[i].isLetter {
                i += 1
            }

            let word = String(chars[wordStart..<i])
            let syllabifiedWord = WordSyllabifier(word: word, rule: rule, softHyphen: softHyphen).syllabify()
            result.append(syllabifiedWord)
        }

        return result.joined()
    }
}
