import Testing
import Foundation
@testable import Syllabreak

struct DetectLanguageTests {
    
    struct TestGroup: Codable {
        let lang: String?
        let cases: [String]
    }
    
    struct TestData: Codable {
        let tests: [TestGroup]
    }
    
    struct LanguageTestCase: CustomTestStringConvertible {
        let text: String
        let expected: [String]
        
        var testDescription: String {
            text
        }
    }
    
    static func loadTestCases() -> [LanguageTestCase] {
        guard let url = Bundle.module.url(forResource: "detect_language_tests", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let testData = try? JSONDecoder().decode(TestData.self, from: data) else {
            Issue.record("Failed to load test cases")
            return []
        }
        
        var testCases: [LanguageTestCase] = []
        for group in testData.tests {
            let expected = group.lang.map { [$0] } ?? []
            for text in group.cases {
                testCases.append(LanguageTestCase(text: text, expected: expected))
            }
        }
        return testCases
    }
    
    @Test(arguments: loadTestCases())
    func detectLanguage(testCase: LanguageTestCase) {
        let s = Syllabreak()
        let result = s.detectLanguage(testCase.text)
        
        if !testCase.expected.isEmpty {
            #expect(!result.isEmpty, 
                    "Failed for '\(testCase.text)': got empty result, expected \(testCase.expected)")
            if !result.isEmpty {
                #expect(result[0] == testCase.expected[0],
                       "Failed for '\(testCase.text)': got \(result[0]) as first (from \(result)), expected \(testCase.expected[0])")
            }
        } else {
            #expect(result == [], 
                   "Failed for '\(testCase.text)': got \(result), expected empty list")
        }
    }
}
