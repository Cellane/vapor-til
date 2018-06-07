@testable import App
import FluentPostgreSQL
import Vapor
import XCTest

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

    func testAcronymShortMustBeAlphanumeric() throws {
        let acronym1 = try Acronym.create(short: "#", long: "Not An Acronym", on: conn)
        let acronym2 = try Acronym.create(short: "###", long: "Also Not Acronym", on: conn)
        let acronym3 = try Acronym.create(on: conn)

        XCTAssertThrowsError(try acronym1.validate())
        XCTAssertThrowsError(try acronym2.validate())
        XCTAssertNoThrow(try acronym3.validate())
    }

    func testAcronymLongMustBeAlphanumericOrWhitespaces() throws {
        let acronym1 = try Acronym.create(short: "TIL", long: "#", on: conn)
        let acronym2 = try Acronym.create(short: "OMG", long: "##", on: conn)
        let acronym3 = try Acronym.create(on: conn)

        XCTAssertThrowsError(try acronym1.validate())
        XCTAssertThrowsError(try acronym2.validate())
        XCTAssertNoThrow(try acronym3.validate())
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

    func testAcronymCanBeSavedWithAPI() throws {
        let user = try User.create(on: conn)
        let acronym = Acronym(short: acronymShort, long: acronymLong, userID: user.id!)
        let receivedAcronym = try app.getResponse(
            to: acronymsURI,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            data: acronym,
            decodeTo: Acronym.self,
            loggedInRequest: true
        )

        XCTAssertEqual(receivedAcronym.short, acronymShort)
        XCTAssertEqual(receivedAcronym.long, acronymLong)
        XCTAssertNotNil(receivedAcronym.id)

        let acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].short, acronymShort)
        XCTAssertEqual(acronyms[0].long, acronymLong)
        XCTAssertEqual(acronyms[0].id, receivedAcronym.id)
    }

    func testGettingASingleAcronymFromTheAPI() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)

        let returnedAcronym = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)", decodeTo: Acronym.self)

        XCTAssertEqual(returnedAcronym.short, acronymShort)
        XCTAssertEqual(returnedAcronym.long, acronymLong)
        XCTAssertEqual(returnedAcronym.id, acronym.id)
    }

    func testUpdatingAnAcronym() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        let newUser = try User.create(on: conn)
        let newLong = "Oh My Gosh"
        let updatedAcronym = Acronym(short: acronymShort, long: newLong, userID: newUser.id!)

        try app.sendRequest(
            to: "\(acronymsURI)\(acronym.id!)",
            method: .PUT,
            headers: ["Content-Type": "application/json"],
            data: updatedAcronym,
            loggedInUser: newUser
        )

        let returnedAcronym = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)", decodeTo: Acronym.self)

        XCTAssertEqual(returnedAcronym.short, acronymShort)
        XCTAssertEqual(returnedAcronym.long, newLong)
        XCTAssertEqual(returnedAcronym.userID, newUser.id)
    }

    func testDeletingAnAcronym() throws {
        let acronym = try Acronym.create(on: conn)
        var acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)

        _ = try app.sendRequest(
            to: "\(acronymsURI)\(acronym.id!)",
            method: .DELETE,
            loggedInRequest: true
        )
        acronyms = try app.getResponse(to: acronymsURI, decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 0)
    }

    func testSearchAcronymShort() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        let acronyms = try app.getResponse(to: "\(acronymsURI)?term=OMG", decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].id, acronym.id)
        XCTAssertEqual(acronyms[0].short, acronymShort)
        XCTAssertEqual(acronyms[0].long, acronymLong)
    }

    func testSearchAcronymLong() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        let acronyms = try app.getResponse(to: "\(acronymsURI)?term=Oh+My+God", decodeTo: [Acronym].self)

        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].id, acronym.id)
        XCTAssertEqual(acronyms[0].short, acronymShort)
        XCTAssertEqual(acronyms[0].long, acronymLong)
    }

    func testGetFirstAcronym() throws {
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        _ = try Acronym.create(on: conn)
        _ = try Acronym.create(on: conn)

        let firstAcronym = try app.getResponse(to: "\(acronymsURI)first", decodeTo: Acronym.self)

        XCTAssertEqual(firstAcronym.id, acronym.id)
        XCTAssertEqual(firstAcronym.short, acronymShort)
        XCTAssertEqual(firstAcronym.long, acronymLong)
    }

    func testSortingAcronyms() throws {
        let short2 = "LOL"
        let long2 = "Laugh Out Loud"
        let acronym1 = try Acronym.create(short: acronymShort, long: acronymLong, on: conn)
        let acronym2 = try Acronym.create(short: short2, long: long2, on: conn)

        let sortedAcronyms = try app.getResponse(to: "\(acronymsURI)sorted", decodeTo: [Acronym].self)

        XCTAssertEqual(sortedAcronyms[0].id, acronym2.id)
        XCTAssertEqual(sortedAcronyms[1].id, acronym1.id)
    }

    func testGettingAnAcronymsUser() throws {
        let user = try User.create(on: conn)
        let acronym = try Acronym.create(user: user, on: conn)

        let acronymsUser = try app.getResponse(
            to: "\(acronymsURI)\(acronym.id!)/user",
            decodeTo: User.Public.self
        )
        XCTAssertEqual(acronymsUser.id, user.id)
        XCTAssertEqual(acronymsUser.name, user.name)
        XCTAssertEqual(acronymsUser.username, user.username)
    }

    func testAcronymsCategories() throws {
        let category = try Category.create(on: conn)
        let category2 = try Category.create(name: "Funny", on: conn)
        let acronym = try Acronym.create(on: conn)
        let request1URL = "\(acronymsURI)\(acronym.id!)/categories/\(category.id!)"
        let request2URL = "\(acronymsURI)\(acronym.id!)/categories/\(category2.id!)"

        _ = try app.sendRequest(to: request1URL, method: .POST, loggedInRequest: true)
        _ = try app.sendRequest(to: request2URL, method: .POST, loggedInRequest: true)

        let categories = try app.getResponse(to: "\(acronymsURI)\(acronym.id!)/categories", decodeTo: [App.Category].self)

        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].id, category.id)
        XCTAssertEqual(categories[0].name, category.name)
        XCTAssertEqual(categories[1].id, category2.id)
        XCTAssertEqual(categories[1].name, category2.name)
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
        ("testAcronymShortMustBeAlphanumeric", testAcronymShortMustBeAlphanumeric),
        ("testAcronymLongMustBeAlphanumericOrWhitespaces", testAcronymLongMustBeAlphanumericOrWhitespaces),
        ("testAcronymsCanBeRetrievedFromAPI", testAcronymsCanBeRetrievedFromAPI),
        ("testAcronymCanBeSavedWithAPI", testAcronymCanBeSavedWithAPI),
        ("testGettingASingleAcronymFromTheAPI", testGettingASingleAcronymFromTheAPI),
        ("testUpdatingAnAcronym", testUpdatingAnAcronym),
        ("testDeletingAnAcronym", testDeletingAnAcronym),
        ("testSearchAcronymShort", testSearchAcronymShort),
        ("testSearchAcronymLong", testSearchAcronymLong),
        ("testGetFirstAcronym", testGetFirstAcronym),
        ("testSortingAcronyms", testSortingAcronyms),
        ("testGettingAnAcronymsUser", testGettingAnAcronymsUser),
        ("testAcronymsCategories", testAcronymsCategories),
        ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests)
    ]
}
