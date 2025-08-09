import Foundation

enum TokenClass {
    case vowel
    case consonant
    case separator
    case other
}

struct Token {
    var surface: String
    let tokenClass: TokenClass
    var isGlide: Bool = false
    var isModifier: Bool = false
    let startIdx: Int
    var endIdx: Int
}
