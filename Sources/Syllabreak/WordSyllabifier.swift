import Foundation

class WordSyllabifier {
    private let word: String
    private let rule: LanguageRule
    private let softHyphen: String
    private let tokens: [Token]
    private let nuclei: [Int]

    init(word: String, rule: LanguageRule, softHyphen: String) {
        self.word = word
        self.rule = rule
        self.softHyphen = softHyphen
        self.tokens = WordSyllabifier.tokenize(word: word, rule: rule)
        self.nuclei = WordSyllabifier.findNuclei(tokens: tokens, rule: rule)
    }

    private static func tokenize(word: String, rule: LanguageRule) -> [Token] {
        let tokenizer = Tokenizer(word: word, rule: rule)
        return tokenizer.tokenize()
    }

    private static func findNuclei(tokens: [Token], rule: LanguageRule) -> [Int] {
        var nuclei: [Int] = []

        // First look for vowels
        for (i, token) in tokens.enumerated() where token.tokenClass == .vowel {
            nuclei.append(i)
        }

        if !nuclei.isEmpty {
            return nuclei
        }

        // If no vowels, look for syllabic consonants
        for (i, token) in tokens.enumerated() {
            if token.tokenClass == .consonant &&
               token.surface.count == 1 &&
               rule.syllabicConsonantSet.contains(Character(token.surface.lowercased())) {
                nuclei.append(i)
            }
        }

        return nuclei
    }

    private func skipSeparatorsForward(_ start: Int) -> Int {
        var pos = start
        while pos < tokens.count && tokens[pos].tokenClass == .separator {
            pos += 1
        }
        return pos
    }

    private func skipSeparatorsBackward(_ start: Int) -> Int {
        var pos = start
        while pos >= 0 && tokens[pos].tokenClass == .separator {
            pos -= 1
        }
        return pos
    }

    private func extractConsonantCluster(left: Int, right: Int) -> ([Token], [Int]) {
        var cluster: [Token] = []
        var clusterIndices: [Int] = []

        for i in left...right {
            if i < tokens.count && tokens[i].tokenClass == .consonant {
                cluster.append(tokens[i])
                clusterIndices.append(i)
            }
        }

        return (cluster, clusterIndices)
    }

    private func findClusterBetweenNuclei(nk: Int, nk1: Int) -> ([Token], [Int]) {
        let left = skipSeparatorsForward(nk + 1)
        let right = skipSeparatorsBackward(nk1 - 1)

        if left > right {
            return ([], [])
        }

        return extractConsonantCluster(left: left, right: right)
    }

    private func isValidOnset(_ consonant1: String, _ consonant2: String, prevNucleusIdx: Int? = nil) -> Bool {
        let onsetCandidate = consonant1.lowercased() + consonant2.lowercased()

        // Check if this cluster requires a long vowel before it
        if rule.clustersOnlyAfterLongSet.contains(onsetCandidate), let prevIdx = prevNucleusIdx {
            // Check if previous nucleus is long (digraph or marked as long)
            if !isLongNucleus(prevIdx) {
                return false
            }
        }

        return rule.clustersKeepNextSet.contains(onsetCandidate)
    }

    private func isLongNucleus(_ nucleusIdx: Int) -> Bool {
        // Check if nucleus at given index is long (digraph vowel or followed by lengthening marker)
        guard nucleusIdx < tokens.count else { return false }

        let vowelToken = tokens[nucleusIdx]

        // Check if this vowel token itself is already a digraph (tokenized as one unit)
        if rule.digraphVowelsSet.contains(vowelToken.surface.lowercased()) {
            return true
        }

        // Check if current vowel + next character forms a digraph vowel
        if nucleusIdx + 1 < tokens.count {
            let nextToken = tokens[nucleusIdx + 1]
            let digraph = vowelToken.surface.lowercased() + nextToken.surface.lowercased()
            if rule.digraphVowelsSet.contains(digraph) {
                return true
            }
        }

        // Single vowel is considered short
        return false
    }

    private func findBoundaryForSingleConsonant(_ clusterIndices: [Int]) -> Int {
        // V-CV: boundary before single consonant
        return clusterIndices[0]
    }

    private func findBoundaryForTwoConsonants(
        _ cluster: [Token],
        _ clusterIndices: [Int],
        prevNucleusIdx: Int? = nil
    ) -> Int {
        // Determine boundary for two-consonant cluster
        if isValidOnset(cluster[0].surface, cluster[1].surface, prevNucleusIdx: prevNucleusIdx) {
            return clusterIndices[0]
        } else {
            return clusterIndices[1]
        }
    }

    private func findBoundaryForLongCluster(
        _ cluster: [Token],
        _ clusterIndices: [Int],
        prevNucleusIdx: Int? = nil
    ) -> Int {
        // Determine boundary for cluster with 3+ consonants
        var boundaryIdx = clusterIndices[clusterIndices.count - 1]

        if cluster.count >= 2 && isValidOnset(
            cluster[cluster.count - 2].surface,
            cluster[cluster.count - 1].surface,
            prevNucleusIdx: prevNucleusIdx
        ) {
            boundaryIdx = clusterIndices[clusterIndices.count - 2]
        }

        return boundaryIdx
    }

    private func findBoundaryInCluster(_ cluster: [Token], _ clusterIndices: [Int], _ nk: Int, _ nk1: Int) -> Int? {
        // Determine where to place boundary in a consonant cluster or between vowels
        if cluster.isEmpty {
            // Check for vowel hiatus (adjacent vowels)
            // If no glides defined and no digraph_vowels, split between vowels
            if rule.glideSet.isEmpty && rule.digraphVowelsSet.isEmpty {
                // Check if nuclei are adjacent (or only separated by modifiers/separators)
                if nk1 - nk == 1 {
                    // Adjacent vowels - place boundary between them
                    return nk1
                }
                // Check if there are only separators between vowels
                var allSeparators = true
                for i in (nk + 1)..<nk1 where tokens[i].tokenClass != .separator {
                    allSeparators = false
                    break
                }
                if allSeparators {
                    // Only separators between vowels - place boundary before second vowel
                    return nk1
                }
            }
            return nil
        } else if cluster.count == 1 {
            return findBoundaryForSingleConsonant(clusterIndices)
        } else if cluster.count == 2 {
            return findBoundaryForTwoConsonants(cluster, clusterIndices, prevNucleusIdx: nk)
        } else {
            return findBoundaryForLongCluster(cluster, clusterIndices, prevNucleusIdx: nk)
        }
    }

    private func placeBoundaries() -> [Int] {
        // Determine syllable boundaries between nuclei
        var boundaries: [Int] = []

        for k in 0..<(nuclei.count - 1) {
            let (cluster, clusterIndices) = findClusterBetweenNuclei(nk: nuclei[k], nk1: nuclei[k + 1])
            if let boundary = findBoundaryInCluster(cluster, clusterIndices, nuclei[k], nuclei[k + 1]) {
                boundaries.append(boundary)
            }
        }

        return boundaries
    }

    func syllabify() -> String {
        // Perform syllabification and return the word with soft hyphens
        if nuclei.count < 2 {
            return word
        }

        let boundaries = placeBoundaries()
        if boundaries.isEmpty {
            return word
        }

        var result: [String] = []
        let boundarySet = Set(boundaries)

        for (i, token) in tokens.enumerated() {
            if boundarySet.contains(i) {
                result.append(softHyphen)
            }
            result.append(token.surface)
        }

        return result.joined()
    }
}
