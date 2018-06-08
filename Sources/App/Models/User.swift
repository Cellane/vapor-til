import Authentication
import Crypto
import FluentPostgreSQL
import Foundation
import Vapor

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String

    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }

    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String

        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User.Public: Content {}
extension User: Parameter {}

extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            try builder.addIndex(to: \.username, isUnique: true)
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \.username
    static let passwordKey: PasswordKey = \.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}

extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return map { user in
            return user.convertToPublic()
        }
    }
}

struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let password = try? BCrypt.hash("password")

        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }

        let user = User(name: "Admin", username: "Admin", password: hashedPassword)

        return user.save(on: connection).transform(to: ())
    }

    static func revert(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return .done(on: connection)
    }
}
