import Foundation
@testable import App
import Vapor
import VaporTestTools

extension TestableProperty where TestableType: Application {
    public static func newTestApp() -> Application {
        var env = Environment.testing
        let app = new({ (config, _, services) in
            try! App.configure(&config, &env, &services)
        }) { router in
        }

        try! App.boot(app)

        return app
    }
}
