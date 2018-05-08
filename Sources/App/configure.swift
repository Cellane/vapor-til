import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    let corsConfiguration = CORSMiddleware.Configuration(allowedOrigin: .all, allowedMethods: [.GET, .PUT], allowedHeaders: [.transferEncoding])
    middlewares.use(CORSMiddleware(configuration: corsConfiguration))
    services.register(middlewares)

    var databases = DatabasesConfig()

    switch env {
    case .testing:
        let databaseConfig = PostgreSQLDatabaseConfig(
            hostname: "localhost",
            port: 5555,
            username: "vapor",
            database: "vapor",
            password: "password"
        )
        let database = PostgreSQLDatabase(config: databaseConfig)

        databases.add(database: database, as: .psql)
    default:
        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let username = Environment.get("DATABASE_USER") ?? "vapor"
        let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        let databaseConfig = PostgreSQLDatabaseConfig(
            hostname: hostname,
            username: username,
            database: databaseName,
            password: password
        )
        let database = PostgreSQLDatabase(config: databaseConfig)

        databases.add(database: database, as: .psql)
    }

    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)

    if env == .testing {
        migrations.add(migration: PopulateUsers.self, database: .psql)
    }
    services.register(migrations)

    var commandConfig = CommandConfig.default()
    commandConfig.use(RevertCommand.self, as: "revert")
    services.register(commandConfig)
}
