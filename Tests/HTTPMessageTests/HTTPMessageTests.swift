import XCTest
@testable import HTTPMessage

class HTTPMessageTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(HTTPMessage().text, "Hello, World!")
    }


    static var allTests : [(String, (HTTPMessageTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
