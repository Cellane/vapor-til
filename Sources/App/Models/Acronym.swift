import Vapor
import FluentPostgreSQL

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    var userID: User.ID

    init(short: String, long: String, userID: User.ID) {
        self.short = short
        self.long = long
        self.userID = userID
    }
}

extension Acronym {
    func willCreate(on connection: PostgreSQLConnection) throws -> EventLoopFuture<Acronym> {
        try validate()

        return Future.map(on: connection) { self }
    }

    func willUpdate(on connection: PostgreSQLConnection) throws -> EventLoopFuture<Acronym> {
        try validate()

        return Future.map(on: connection) { self }
    }
}

extension Acronym: PostgreSQLModel {}
extension Acronym: Content {}
extension Acronym: Parameter {}

extension Acronym {
    var user: Parent<Acronym, User> {
        return parent(\.userID)
    }

    var categories: Siblings<Acronym, Category, AcronymCategoryPivot> {
        return siblings()
    }
}

extension Acronym: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addReference(from: \.userID, to: \User.id)
        }
    }
}

extension Acronym: Validatable {
    static func validations() throws -> Validations<Acronym> {
        var validations = Validations(Acronym.self)

        try validations.add(\.short, .count(2...) && .alphanumeric)
        try validations.add(\.long, .characterSet(.alphanumerics + .whitespaces))

        return validations
    }
}
