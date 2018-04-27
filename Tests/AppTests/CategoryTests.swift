@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class CategoryTests: XCTestCase {
    let categoriesURI = "/api/categories/"
    let categoryName = "Teenager"
    var app: Application!
    var conn: PostgreSQLConnection!

    override func setUp() {
        try! Application.reset()

        app = try! Application.testable()
        conn = try! app.requestConnection(to: .psql).wait()
    }

    override func tearDown() {
        app.releaseConnection(conn, to: .psql)
    }

    func testCategoriesCanBeRetrievedFromAPI() throws {
        let category = try Category.create(name: categoryName, on: conn)
        _ = try Category.create(on: conn)

        let categories = try app.getResponse(to: categoriesURI, decodeTo: [App.Category].self)

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].name, categoryName)
        XCTAssertEqual(categories[0].id, category.id)
    }

    func testCategoryCanBeSavedWithAPI() throws {
        let category = Category(name: categoryName)
        let receivedCategory = try app.getResponse(to: categoriesURI, method: .POST, headers: ["Content-Type": "application/json"], data: category, decodeTo: Category.self)

        XCTAssertEqual(receivedCategory.name, categoryName)
        XCTAssertNotNil(receivedCategory.id)
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
        ("testCategoriesCanBeRetrievedFromAPI", testCategoriesCanBeRetrievedFromAPI),
        ("testCategoryCanBeSavedWithAPI", testCategoryCanBeSavedWithAPI),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests)
    ]
}
