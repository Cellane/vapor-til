import App
import Dispatch
import XCTest
import Vapor
import VaporTestTools

final class AppTests: XCTestCase {
    var app: Application!

    static let allTests = [
        ("testHello", testHello),
        //("testNotFound", testNotFound)
    ]

    override func setUp() {
        super.setUp()
        
        app = Application.testable.newTestApp()
    }

    func testHello() {
        let req = HTTPRequest.testable.get(uri: "/api/acronyms")
        let r = app.testable.response(to: req)
        let res = r.response
        
        res.testable.debug()
        
        XCTAssertTrue(res.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
        XCTAssertTrue(res.testable.has(contentLength: 13), "Wrong content length")
        XCTAssertTrue(res.testable.has(content: "Hello, world!"), "Incorrect content")
    }
}
