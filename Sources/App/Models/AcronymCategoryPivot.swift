import Foundation
import FluentPostgreSQL

final class AcronymCategoryPivot: PostgreSQLUUIDPivot {
    var id: UUID?
    var acronymID: Acronym.ID
    var categoryID: Category.ID

    typealias Left = Acronym
    typealias Right = Category

    static var leftIDKey: LeftIDKey = \.acronymID
    static var rightIDKey: RightIDKey = \.categoryID

    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}

extension AcronymCategoryPivot: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addReference(from: \.acronymID, to: \Acronym.id)
            try builder.addReference(from: \.categoryID, to: \Category.id)
        }
    }
}

extension AcronymCategoryPivot: ModifiablePivot {}
