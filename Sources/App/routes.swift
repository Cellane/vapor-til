import Routing
import Vapor
import Fluent

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    let acronymsController = AcronymsController()
    let usersController = UsersController()
    let categoriesController = CategoriesController()
    let uploadsController = UploadsController()
    let websiteController = WebsiteController()

    try router.register(collection: acronymsController)
    try router.register(collection: usersController)
    try router.register(collection: categoriesController)
    try router.register(collection: uploadsController)
    try router.register(collection: websiteController)
}
