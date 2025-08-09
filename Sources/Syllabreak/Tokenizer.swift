import Foundation

class Tokenizer {
    private let word: String
    private let wordLower: String
    private let rule: LanguageRule
    private var tokens: [Token] = []
    private var pos = 0

    init(word: String, rule: LanguageRule) {
        self.word = word
        self.wordLower = word.lowercased()
        self.rule = rule
    }

    func tokenize() -> [Token] {
        while pos < word.count {
            if tryMatchLeftModifier() {
                continue
            }
            if tryMatchSeparator() {
                continue
            }
            if tryMatchConsonantDigraph() {
                continue
            }
            if tryMatchVowelDigraph() {
                continue
            }
            addSingleCharacterToken()
        }
        return tokens
    }

    private func tryMatchLeftModifier() -> Bool {
        let char = wordLower[wordLower.index(wordLower.startIndex, offsetBy: pos)]
        if !rule.modifiersAttachLeftSet.contains(char) {
            return false
        }

        if !tokens.isEmpty {
            let wordChar = word[word.index(word.startIndex, offsetBy: pos)]
            tokens[tokens.count - 1].surface += String(wordChar)
            tokens[tokens.count - 1].endIdx = pos + 1
            tokens[tokens.count - 1].isModifier = true
        } else {
            tokens.append(
                Token(
                    surface: String(word[word.index(word.startIndex, offsetBy: pos)]),
                    tokenClass: .other,
                    isModifier: true,
                    startIdx: pos,
                    endIdx: pos + 1
                )
            )
        }
        pos += 1
        return true
    }

    private func tryMatchSeparator() -> Bool {
        let char = wordLower[wordLower.index(wordLower.startIndex, offsetBy: pos)]
        if !rule.modifiersSeparatorsSet.contains(char) {
            return false
        }

        tokens.append(
            Token(
                surface: String(word[word.index(word.startIndex, offsetBy: pos)]),
                tokenClass: .separator,
                startIdx: pos,
                endIdx: pos + 1
            )
        )
        pos += 1
        return true
    }

    private func tryMatchConsonantDigraph() -> Bool {
        for length in [2, 1] {
            if pos + length > word.count {
                continue
            }
            let startIdx = wordLower.index(wordLower.startIndex, offsetBy: pos)
            let endIdx = wordLower.index(startIdx, offsetBy: length)
            let substr = String(wordLower[startIdx..<endIdx])

            if rule.dontSplitDigraphsSet.contains(substr) {
                let wordStartIdx = word.index(word.startIndex, offsetBy: pos)
                let wordEndIdx = word.index(wordStartIdx, offsetBy: length)
                tokens.append(
                    Token(
                        surface: String(word[wordStartIdx..<wordEndIdx]),
                        tokenClass: .consonant,
                        startIdx: pos,
                        endIdx: pos + length
                    )
                )
                pos += length
                return true
            }
        }
        return false
    }

    private func tryMatchVowelDigraph() -> Bool {
        for length in [2, 1] {
            if pos + length > word.count {
                continue
            }
            let startIdx = wordLower.index(wordLower.startIndex, offsetBy: pos)
            let endIdx = wordLower.index(startIdx, offsetBy: length)
            let substr = String(wordLower[startIdx..<endIdx])

            if rule.digraphVowelsSet.contains(substr) {
                let wordStartIdx = word.index(word.startIndex, offsetBy: pos)
                let wordEndIdx = word.index(wordStartIdx, offsetBy: length)
                tokens.append(
                    Token(
                        surface: String(word[wordStartIdx..<wordEndIdx]),
                        tokenClass: .vowel,
                        startIdx: pos,
                        endIdx: pos + length
                    )
                )
                pos += length
                return true
            }
        }
        return false
    }

    private func addSingleCharacterToken() {
        let char = wordLower[wordLower.index(wordLower.startIndex, offsetBy: pos)]
        let wordChar = word[word.index(word.startIndex, offsetBy: pos)]

        if rule.vowelSet.contains(char) {
            tokens.append(
                Token(
                    surface: String(wordChar),
                    tokenClass: .vowel,
                    startIdx: pos,
                    endIdx: pos + 1
                )
            )
        } else if rule.consonantSet.contains(char) || rule.glideSet.contains(char) || rule.sonorantSet.contains(char) {
            let isGlide = rule.glideSet.contains(char)
            tokens.append(
                Token(
                    surface: String(wordChar),
                    tokenClass: .consonant,
                    isGlide: isGlide,
                    startIdx: pos,
                    endIdx: pos + 1
                )
            )
        } else {
            tokens.append(
                Token(
                    surface: String(wordChar),
                    tokenClass: .other,
                    startIdx: pos,
                    endIdx: pos + 1
                )
            )
        }
        pos += 1
    }
}
