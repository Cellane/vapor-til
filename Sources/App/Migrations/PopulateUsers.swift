import FluentPostgreSQL

final class PopulateUsers: Migration {
    typealias Database = PostgreSQLDatabase

    static let usersData = [
        ("Milan Vit", "Cellane"),
        ("Nalim Tiv", "Voilane")
    ]

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        let futures = usersData.map { userData in
            return User(name: userData.0, username: userData.1)
                .create(on: connection)
                .map(to: Void.self) { _ in return }
        }

        return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        do {
            let futures = try usersData.map { userData in
                return try User.query(on: connection).filter(\User.username == userData.1).delete()
            }

            return Future<Void>.andAll(futures, eventLoop: connection.eventLoop)
        } catch {
            return connection.eventLoop.newFailedFuture(error: error)
        }
    }
}
