import Testing
import Foundation
@testable import Syllabreak

struct SyllabifyTests {
    
    struct TestSection: Codable {
        let section: String
        let lang: String?
        let cases: [TestCase]
    }
    
    struct TestCase: Codable {
        let text: String
        let want: String
    }
    
    struct TestData: Codable {
        let tests: [TestSection]
    }
    
    struct LoadedTestCase: CustomTestStringConvertible {
        let section: String
        let lang: String?
        let text: String
        let want: String
        
        var testDescription: String {
            "[\(section)] \(text)"
        }
    }
    
    static func loadTestCases() -> [LoadedTestCase] {
        guard let url = Bundle.module.url(forResource: "syllabify_tests", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let testData = try? JSONDecoder().decode(TestData.self, from: data) else {
            Issue.record("Failed to load test cases")
            return []
        }
        
        var testCases: [LoadedTestCase] = []
        for section in testData.tests {
            for testCase in section.cases {
                testCases.append(LoadedTestCase(
                    section: section.section,
                    lang: section.lang,
                    text: testCase.text,
                    want: testCase.want
                ))
            }
        }
        return testCases
    }
    
    @Test(arguments: loadTestCases())
    func syllabify(testCase: LoadedTestCase) {
        let syllabifier = Syllabreak(softHyphen: "-")
        
        let result: String
        if let lang = testCase.lang {
            result = syllabifier.syllabify(testCase.text, lang: lang)
        } else {
            result = syllabifier.syllabify(testCase.text)
        }
        
        #expect(result == testCase.want,
               "[\(testCase.section)] Failed for '\(testCase.text)': got '\(result)', want '\(testCase.want)'")
    }
}
