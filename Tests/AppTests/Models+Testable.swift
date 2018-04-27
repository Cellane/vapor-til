@testable import App
import FluentPostgreSQL

extension App.Category {
    static func create(name: String = "Random", on connection: PostgreSQLConnection) throws -> App.Category {
        let category = Category(name: name)

        return try category.save(on: connection).wait()
    }
}
