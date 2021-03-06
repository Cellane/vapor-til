import Authentication
import FluentPostgreSQL
import Foundation
import Vapor

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID

    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: PostgreSQLUUIDModel {}
extension Token: Migration {}
extension Token: Content {}

extension Token: Authentication.Token {
    typealias UserType = User

    static let userIDKey: UserIDKey = \.userID
}

extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \.token
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 64)

        return try Token(token: random.base64EncodedString(), userID: user.requireID())
    }
}
