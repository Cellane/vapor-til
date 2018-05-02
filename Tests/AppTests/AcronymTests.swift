@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class AcronymTests: XCTestCase {
    let acronymsURI = "/api/acronyms/"
    let acronymShort = "OMG"
    let acronymLong = "Oh My God"
    var app: Application!
    var conn: PostgreSQLConnection!

    override func setUp() {
        try! Application.reset()

        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }

    override func tearDown() {
        conn.close()
    }

    func testAcronymsCanBeRetrievedFromAPI() throws {
        let acronym1 = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        _ = try Acronym.create(on: conn)
        let acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 2)
        XCTAssertEqual(acronyms[0].short, acronymShort)
        XCTAssertEqual(acronyms[0].long, acronymLong)
        XCTAssertEqual(acronyms[0].id, acronym1.id)
    }

    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        let thisClass = type(of: self)
        let linuxCount = thisClass.allTests.count
        let darwinCount = Int(thisClass.defaultTestSuite.testCaseCount)
        XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }

    static let allTests = [
        ("testAcronymsCanBeRetrievedFromAPI", testAcronymsCanBeRetrievedFromAPI),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests)
    ]
}
