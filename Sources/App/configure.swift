import FluentPostgreSQL
import Vapor
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    // Configure a database
    var databases = DatabasesConfig()
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let databaseName: String
    let databasePort: Int
    if (env == .testing) {
        databaseName = "vapor-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 5433
        } else {
            databasePort = 5433
        }
    } else {
        databaseName = "vapor"
        databasePort = 5432
    }
    
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        port: databasePort,
        username: "vapor",
        database: databaseName,
        password: "password")
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: DatabaseIdentifier<User.Database>.psql)
    migrations.add(model: Acronym.self, database: DatabaseIdentifier<Acronym.Database>.psql)
    migrations.add(model: Category.self, database: DatabaseIdentifier<Category.Database>.psql)
    migrations.add(model: AcronymCategoryPivot.self, database: DatabaseIdentifier<AcronymCategoryPivot.Database>.psql)
    migrations.add(model: Token.self, database: DatabaseIdentifier<Token.Database>.psql)
    migrations.add(migration: AdminUser.self, database: DatabaseIdentifier<AdminUser.Database>.psql)
    services.register(migrations)
    
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    try services.register(AuthenticationProvider())
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
}
