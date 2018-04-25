import FluentPostgreSQL

final class TestDatabaseWipe: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let query = """
        DROP OWNED BY \"vapor-test\";
        CREATE TABLE public.fluent (
            id uuid NOT NULL,
            name text NOT NULL,
            batch bigint NOT NULL,
            "createdAt" timestamp without time zone,
            "updatedAt" timestamp without time zone
        );

        ALTER TABLE public.fluent OWNER TO "vapor-test";
        ALTER TABLE ONLY public.fluent
            ADD CONSTRAINT fluent_pkey PRIMARY KEY (id);
        """

        return connection.simpleQuery(query).transform(to: Void())
    }

    static func revert(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return connection.eventLoop.newSucceededFuture(result: Void())
    }
}
