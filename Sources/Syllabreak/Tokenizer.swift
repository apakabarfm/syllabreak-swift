import Foundation

class Tokenizer {
    private let wordScalars: [Unicode.Scalar]
    private let scalars: [Unicode.Scalar]
    private let rule: LanguageRule
    private var tokens: [Token] = []
    private var pos = 0

    private static let combiningDiaeresis: Unicode.Scalar = "\u{0308}"

    init(word: String, rule: LanguageRule) {
        self.wordScalars = Array(word.unicodeScalars)
        self.scalars = Array(word.lowercased().unicodeScalars)
        self.rule = rule
    }

    func tokenize() -> [Token] {
        while pos < scalars.count {
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

    private func surface(start: Int, end: Int) -> String {
        String(String.UnicodeScalarView(wordScalars[start..<end]))
    }

    private func charAtLower(_ index: Int) -> Character {
        Character(scalars[index])
    }

    private static func isNonspacingMark(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.generalCategory == .nonspacingMark
    }

    private func tryMatchLeftModifier() -> Bool {
        let scalar = scalars[pos]
        let char = Character(scalar)
        // Explicit list from the rule, plus any Unicode nonspacing mark —
        // the Mn fallback covers polytonic Greek breathings / accents /
        // iota subscript and any other combining mark transparently.
        let attaches = rule.modifiersAttachLeftSet.contains(char) || Self.isNonspacingMark(scalar)
        if !attaches {
            return false
        }

        if !tokens.isEmpty {
            tokens[tokens.count - 1].surface += surface(start: pos, end: pos + 1)
            tokens[tokens.count - 1].endIdx = pos + 1
            tokens[tokens.count - 1].isModifier = true
        } else {
            tokens.append(
                Token(
                    surface: surface(start: pos, end: pos + 1),
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
        let char = charAtLower(pos)
        if !rule.modifiersSeparatorsSet.contains(char) {
            return false
        }

        tokens.append(
            Token(
                surface: surface(start: pos, end: pos + 1),
                tokenClass: .separator,
                startIdx: pos,
                endIdx: pos + 1
            )
        )
        pos += 1
        return true
    }

    private func tryMatchConsonantDigraph() -> Bool {
        tryMatchDigraph(source: rule.dontSplitDigraphsSet, tokenClass: .consonant)
    }

    private func tryMatchVowelDigraph() -> Bool {
        tryMatchDigraph(source: rule.digraphVowelsSet, tokenClass: .vowel)
    }

    private func tryMatchDigraph(source: Set<String>, tokenClass: TokenClass) -> Bool {
        // Direct substring match (catches entries whose marks sit on a
        // vowel that is part of the digraph itself, e.g. deu "üh").
        for length in [3, 2, 1] {
            let end = pos + length
            if end > scalars.count {
                continue
            }
            let substr = String(String.UnicodeScalarView(scalars[pos..<end]))
            if source.contains(substr) && !diaeresisVetoesAt(end) {
                addDigraphToken(end: end, tokenClass: tokenClass)
                pos = end
                return true
            }
        }

        // Mn-skipping fallback (catches breath/accent between two base
        // letters of a diphthong, e.g. Greek "ἀι" = α + U+0313 + ι).
        let positions = scanBases()
        if positions.isEmpty {
            return false
        }
        let bases = basesAtPositions(positions)
        for length in [3, 2, 1] where bases.count >= length {
            let candidate = bases.prefix(length).map(String.init).joined()
            if !source.contains(candidate) {
                continue
            }
            let end = positions[length - 1]
            if diaeresisVetoesAt(end) {
                continue
            }
            addDigraphToken(end: end, tokenClass: tokenClass)
            pos = end
            return true
        }
        return false
    }

    private func addDigraphToken(end: Int, tokenClass: TokenClass) {
        let isGlide: Bool
        if tokenClass == .vowel {
            let scalarSlice = scalars[pos..<end]
            isGlide = scalarSlice.contains { rule.glideSet.contains(Character($0)) }
        } else {
            isGlide = false
        }
        tokens.append(
            Token(
                surface: surface(start: pos, end: end),
                tokenClass: tokenClass,
                isGlide: isGlide,
                startIdx: pos,
                endIdx: end
            )
        )
    }

    private func scanBases() -> [Int] {
        // End-positions of up to 3 upcoming base letters, skipping Mn marks.
        var positions: [Int] = []
        var p = pos
        while p < scalars.count && positions.count < 3 {
            if Self.isNonspacingMark(scalars[p]) {
                p += 1
                continue
            }
            positions.append(p + 1)
            p += 1
        }
        return positions
    }

    private func basesAtPositions(_ positions: [Int]) -> [Character] {
        var chars: [Character] = []
        for (idx, end) in positions.enumerated() {
            let start = idx == 0 ? pos : positions[idx - 1]
            for q in stride(from: end - 1, through: start, by: -1)
                where !Self.isNonspacingMark(scalars[q]) {
                chars.append(Character(scalars[q]))
                break
            }
        }
        return chars
    }

    private func diaeresisVetoesAt(_ endPos: Int) -> Bool {
        // Diaeresis (U+0308) attached to the closing base of a candidate
        // digraph signals hiatus, not a diphthong (αϊ / Μαΐου / naïf).
        for p in endPos..<scalars.count {
            let scalar = scalars[p]
            if !Self.isNonspacingMark(scalar) {
                return false
            }
            if scalar == Self.combiningDiaeresis {
                return true
            }
        }
        return false
    }

    private func addSingleCharacterToken() {
        let scalar = scalars[pos]
        let char = Character(scalar)

        let tokenClass: TokenClass
        var isGlide = false

        if rule.vowelSet.contains(char) {
            tokenClass = .vowel
        } else if rule.consonantSet.contains(char) || rule.glideSet.contains(char) || rule.sonorantSet.contains(char) {
            tokenClass = .consonant
            isGlide = rule.glideSet.contains(char)
        } else {
            tokenClass = .other
        }

        tokens.append(
            Token(
                surface: surface(start: pos, end: pos + 1),
                tokenClass: tokenClass,
                isGlide: isGlide,
                startIdx: pos,
                endIdx: pos + 1
            )
        )
        pos += 1
    }
}
