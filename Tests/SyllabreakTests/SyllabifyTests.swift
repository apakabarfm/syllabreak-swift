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

    struct LoadedTestCase {
        let section: String
        let lang: String?
        let text: String
        let want: String
    }

    func loadTestCases() -> [LoadedTestCase] {
        guard let url = Bundle.module.url(forResource: "syllabify_tests", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let testData = try? JSONDecoder().decode(TestData.self, from: data) else {
            XCTFail("Failed to load test cases")
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

    func testSyllabify() {
        let syllabifier = Syllabreak(softHyphen: "-")
        let testCases = loadTestCases()

        for testCase in testCases {
            let result: String
            if let lang = testCase.lang {
                result = syllabifier.syllabify(testCase.text, lang: lang)
            } else {
                result = syllabifier.syllabify(testCase.text)
            }
            let section = testCase.section
            let text = testCase.text
            let want = testCase.want
            XCTAssertEqual(result, want, "[\(section)] Failed for '\(text)': got '\(result)', want '\(want)'")
        }
    }
}
