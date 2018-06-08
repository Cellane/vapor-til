import Authentication
import Fluent
import FluentSQL
import FluentPostgreSQL
import Vapor

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")

        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)

        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let protected = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)

        protected.post(AcronymCreateData.self, use: createHandler)
        protected.put(Acronym.parameter, use: updateHandler)
        protected.delete(Acronym.parameter, use: deleteHandler)
        protected.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
    }

    func getAllHandler(_ req: Request) -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }

    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }

    func createHandler(_ req: Request, data: AcronymCreateData) throws -> Future<Acronym> {
        let user = try req.requireAuthenticated(User.self)
        let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())

        return acronym.save(on: req)
    }

    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(
            to: Acronym.self,
            req.parameters.next(Acronym.self),
            req.content.decode(AcronymCreateData.self)
        ) { acronym, updatedAcronym in
            let user = try req.requireAuthenticated(User.self)

            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            acronym.userID = try user.requireID()

            return acronym.save(on: req)
        }
    }

    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).flatMap { acronym in
            return acronym.delete(on: req).transform(to: .noContent)
        }
    }

    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return try Acronym.query(on: req)
            .group(.or) { or in
                try or.filter(\.short == searchTerm)
                try or.filter(\.long == searchTerm)
            }
            .all()
    }

    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map { acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }

            return acronym
        }
    }

    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try Acronym.query(on: req)
            .sort(\.short, .ascending)
            .all()
    }

    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Acronym.self).flatMap { acronym in
            return try acronym.user.get(on: req).convertToPublic()
        }
    }

    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Acronym.self),
            req.parameters.next(Category.self)
        ) { acronym, category in
            return acronym.categories.attach(category, on: req).transform(to: .created)
        }
    }

    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap { acronym in
            return try acronym.categories.query(on: req).all()
        }
    }

    struct AcronymCreateData: Content {
        let short: String
        let long: String
    }
}
