@testable import App
import Dispatch
import XCTest
import Vapor
import VaporTestTools

final class AppTests: XCTestCase {
    var app: Application!

    static let allTests = [
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests),
        ("testEmptyContent", testEmptyContent),
        ("testCreateCategory", testCreateCategory)
    ]

    override func setUp() {
        super.setUp()

        app = Application.testable.newTestApp()
    }

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.allTests.count
        let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
        XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

    func testEmptyContent() throws {
        let req = HTTPRequest.testable.get(uri: "/api/categories")
        let res = app.testable.response(to: req).response
        let content = res.testable.content(as: [App.Category].self)!

        //res.testable.debug()

        XCTAssertTrue(res.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(res.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
        XCTAssertEqual(content.count, 0, "Incorrect content")
    }

    func testCreateCategory() throws {
        let categoryData = try JSONEncoder().encode(Category(name: "Teenager"))
        let postReq = HTTPRequest.testable.post(uri: "/api/categories", data: categoryData, headers: ["Content-Type": "application/json"])
        let postRes = app.testable.response(to: postReq).response
        let postContent = postRes.testable.content(as: App.Category.self)!

        //postRes.testable.debug()

        XCTAssertTrue(postRes.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(postRes.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
        XCTAssertEqual(postContent.name, "Teenager", "Incorrect content")

        let getReq = HTTPRequest.testable.get(uri: "/api/categories")
        let getRes = app.testable.response(to: getReq).response
        let getContent = getRes.testable.content(as: [App.Category].self)!

        //getRes.testable.debug()

        XCTAssertTrue(getRes.testable.has(statusCode: .ok), "Wrong status code")
        XCTAssertTrue(getRes.testable.has(contentType: "application/json; charset=utf-8"), "Missing content type")
        XCTAssertEqual(getContent.count, 1, "Category was not created")
    }
}
