import Foundation

struct LanguageRule: Codable {
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
}
