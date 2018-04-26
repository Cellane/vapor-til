import FluentPostgreSQL

final class TestDatabaseWipe: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        // This query must first verify that it's run on test database so that we never ever EVER drop production database, of course.
        // One way of sort-of ensuring this would be at least having different username, so that DROP OWNED BY would silently fail as
        // there wouldn't be anything really owned by test user on production server – is that enough of a guarantee? ¯\_(ツ)_/¯
        // Definitely needs discussion.
        let query = """
        DROP OWNED BY "vapor";
        CREATE TABLE public.fluent (
            id uuid NOT NULL,
            name text NOT NULL,
            batch bigint NOT NULL,
            "createdAt" timestamp without time zone,
            "updatedAt" timestamp without time zone
        );

        ALTER TABLE public.fluent OWNER TO "vapor";
        ALTER TABLE ONLY public.fluent
            ADD CONSTRAINT fluent_pkey PRIMARY KEY (id);
        """

        return connection.simpleQuery(query).transform(to: Void())
    }

    static func revert(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return connection.eventLoop.newSucceededFuture(result: Void())
    }
}
