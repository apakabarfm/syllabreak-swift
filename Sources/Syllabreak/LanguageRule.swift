import Foundation

struct LanguageRule: Codable, Sendable {
    let lang: String
    let vowels: String
    let consonants: String
    let sonorants: String
    let clustersKeepNext: [String]?
    let dontSplitDigraphs: [String]?
    let digraphVowels: [String]?
    let glides: String?
    let syllabicConsonants: String?
    let modifiersAttachLeft: String?
    let modifiersAttachRight: String?
    let modifiersSeparators: String?
    let clustersOnlyAfterLong: [String]?
    let splitHiatus: Bool?
    let finalSemivowels: String?
    let finalSequencesKeep: [String]?
    let suffixesBreakVre: [String]?
    let suffixesKeepVre: [String]?
    // Lowercased word -> hyphen-marked split. Overrides the algorithm for
    // individual words that escape the general rules (e.g. BCMS "dvije",
    // "prije" — graphic -ije- not from jat, see Matešić 2015 rule P11).
    let exceptions: [String: String]?
    // Compact-form digraph geminates -> expanded form, applied before
    // tokenisation. Hungarian writes long double digraphs in a simplified
    // form (ssz=sz+sz, ggy=gy+gy, ...) but at a line break both halves
    // are restored in full (asz-szony, meny-nyi).
    let geminateDigraphs: [String: String]?

    struct GeminateSpan {
        let start: Int
        let length: Int
        let compactOriginal: String
    }

    // Computed properties for sets
    var vowelSet: Set<Character> {
        Set(vowels)
    }

    var consonantSet: Set<Character> {
        Set(consonants)
    }

    var sonorantSet: Set<Character> {
        Set(sonorants)
    }

    var clustersKeepNextSet: Set<String> {
        Set(clustersKeepNext ?? [])
    }

    var dontSplitDigraphsSet: Set<String> {
        Set(dontSplitDigraphs ?? [])
    }

    var digraphVowelsSet: Set<String> {
        Set(digraphVowels ?? [])
    }

    var glideSet: Set<Character> {
        Set(glides ?? "")
    }

    var syllabicConsonantSet: Set<Character> {
        Set(syllabicConsonants ?? "")
    }

    var modifiersAttachLeftSet: Set<Character> {
        Set(modifiersAttachLeft ?? "")
    }

    var modifiersAttachRightSet: Set<Character> {
        Set(modifiersAttachRight ?? "")
    }

    var modifiersSeparatorsSet: Set<Character> {
        Set(modifiersSeparators ?? "")
    }

    var clustersOnlyAfterLongSet: Set<String> {
        Set(clustersOnlyAfterLong ?? [])
    }

    var finalSemivowelsSet: Set<Character> {
        Set(finalSemivowels ?? "")
    }

    var finalSequencesKeepSet: Set<String> {
        Set(finalSequencesKeep ?? [])
    }

    var suffixesBreakVreSet: Set<String> {
        Set(suffixesBreakVre ?? [])
    }

    var suffixesKeepVreSet: Set<String> {
        Set(suffixesKeepVre ?? [])
    }

    var allChars: Set<Character> {
        vowelSet.union(consonantSet)
    }

    // Additional property for unique chars (will be set by MetaRule)
    var uniqueChars: Set<Character> = []

    private enum CodingKeys: String, CodingKey {
        case lang
        case vowels
        case consonants
        case sonorants
        case clustersKeepNext = "clusters_keep_next"
        case dontSplitDigraphs = "dont_split_digraphs"
        case digraphVowels = "digraph_vowels"
        case glides
        case syllabicConsonants = "syllabic_consonants"
        case modifiersAttachLeft = "modifiers_attach_left"
        case modifiersAttachRight = "modifiers_attach_right"
        case modifiersSeparators = "modifiers_separators"
        case clustersOnlyAfterLong = "clusters_only_after_long"
        case splitHiatus = "split_hiatus"
        case finalSemivowels = "final_semivowels"
        case finalSequencesKeep = "final_sequences_keep"
        case suffixesBreakVre = "suffixes_break_vre"
        case suffixesKeepVre = "suffixes_keep_vre"
        case exceptions
        case geminateDigraphs = "geminate_digraphs"
    }

    func isVowel(_ char: Character) -> Bool {
        return vowelSet.contains(char)
    }

    func isConsonant(_ char: Character) -> Bool {
        return consonantSet.contains(char)
    }

    func containsChar(_ char: Character) -> Bool {
        return allChars.contains(char)
    }

    func calculateMatchScore(_ text: String) -> Double {
        let cleanText = text.lowercased().filter { $0.isLetter }
        if cleanText.isEmpty {
            return 0.0
        }

        let matching = cleanText.filter { containsChar($0) }.count
        return Double(matching) / Double(cleanText.count)
    }

    /// Expand compact-form digraph geminates (Hungarian ssz, ggy, ...).
    /// Returns the expanded string and a list of spans. Each span carries
    /// (start_in_expanded, length_in_expanded, compact_original_text) so the
    /// renderer can decide whether to keep the expanded form (when a boundary
    /// falls inside) or restore the compact form (when it doesn't).
    func expandGeminateDigraphs(_ word: String) -> (String, [GeminateSpan]) {
        guard let geminates = geminateDigraphs, !geminates.isEmpty else {
            return (word, [])
        }
        let patterns = geminates.sorted { $0.key.count > $1.key.count }
        let wordChars = Array(word)
        let wordLower = word.lowercased()
        let lowerChars = Array(wordLower)
        var result = ""
        var spans: [GeminateSpan] = []
        var i = 0
        var expandedPos = 0
        while i < wordChars.count {
            var matched = false
            for (short, long) in patterns {
                let shortLen = short.count
                if i + shortLen <= wordChars.count {
                    let candidate = String(lowerChars[i..<(i + shortLen)])
                    if candidate == short {
                        let originalCompact = String(wordChars[i..<(i + shortLen)])
                        let expansion: String
                        if originalCompact == originalCompact.uppercased() {
                            expansion = long.uppercased()
                        } else if originalCompact.first?.isUppercase == true {
                            let head = long.prefix(1).uppercased()
                            let tail = long.dropFirst().lowercased()
                            expansion = head + tail
                        } else {
                            expansion = long
                        }
                        spans.append(GeminateSpan(
                            start: expandedPos,
                            length: expansion.count,
                            compactOriginal: originalCompact
                        ))
                        result += expansion
                        expandedPos += expansion.count
                        i += shortLen
                        matched = true
                        break
                    }
                }
            }
            if !matched {
                result.append(wordChars[i])
                expandedPos += 1
                i += 1
            }
        }
        return (result, spans)
    }
}
