import XCTest
@testable import Syllabreak

final class DetectLanguageTests: XCTestCase {

    struct TestGroup: Codable {
        let lang: String?
        let cases: [String]
    }

    struct TestData: Codable {
        let tests: [TestGroup]
    }

    func loadTestCases() -> [(text: String, expected: [String])] {
        guard let url = Bundle.module.url(forResource: "detect_language_tests", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let testData = try? JSONDecoder().decode(TestData.self, from: data) else {
            XCTFail("Failed to load test cases")
            return []
        }

        var testCases: [(String, [String])] = []
        for group in testData.tests {
            let expected = group.lang.map { [$0] } ?? []
            for text in group.cases {
                testCases.append((text, expected))
            }
        }
        return testCases
    }

    func testDetectLanguage() {
        let s = Syllabreak()
        let testCases = loadTestCases()

        for (text, expected) in testCases {
            let result = s.detectLanguage(text)

            if !expected.isEmpty {
                XCTAssertFalse(result.isEmpty, "Failed for '\(text)': got empty result, expected \(expected)")
                if !result.isEmpty {
                    XCTAssertEqual(
                        result[0], expected[0],
                        "Failed for '\(text)': got \(result[0]) as first (from \(result)), expected \(expected[0])"
                    )
                }
            } else {
                XCTAssertEqual(result, [], "Failed for '\(text)': got \(result), expected empty list")
            }
        }
    }
}
