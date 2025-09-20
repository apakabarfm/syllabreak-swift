import Foundation
import SwiftEmbed

public final class Syllabreak: Sendable {
    public static let defaultSoftHyphen = "\u{00AD}"
    private let softHyphen: String
    private let metaRule: MetaRule

    struct RulesData: Codable {
        let rules: [LanguageRule]
    }

    private static var rulesData: RulesData {
        Embedded.getYAML(Bundle.module, path: "rules.yaml")
    }

    public init(softHyphen: String = defaultSoftHyphen) {
        self.softHyphen = softHyphen
        self.metaRule = MetaRule(rules: Self.rulesData.rules)
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
        for rule in metaRule.rules where rule.lang == lang {
            return rule
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
