import XCTest
@testable import Syllabreak

final class SyllabifyTests: XCTestCase {

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

    func loadTestCases() -> [(section: String, lang: String?, text: String, want: String)] {
        guard let url = Bundle.module.url(forResource: "syllabify_tests", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let testData = try? JSONDecoder().decode(TestData.self, from: data) else {
            XCTFail("Failed to load test cases")
            return []
        }

        var testCases: [(String, String?, String, String)] = []
        for section in testData.tests {
            for testCase in section.cases {
                testCases.append((section.section, section.lang, testCase.text, testCase.want))
            }
        }
        return testCases
    }

    func testSyllabify() {
        let syllabifier = Syllabreak(softHyphen: "-")
        let testCases = loadTestCases()

        for (section, lang, text, want) in testCases {
            let result: String
            if let lang = lang {
                result = syllabifier.syllabify(text, lang: lang)
            } else {
                result = syllabifier.syllabify(text)
            }
            XCTAssertEqual(result, want, "[\(section)] Failed for '\(text)': got '\(result)', want '\(want)'")
        }
    }
}
