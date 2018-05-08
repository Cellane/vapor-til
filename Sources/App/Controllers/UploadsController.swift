import Foundation
import Vapor
import Crypto

/**
 * This is a quick demo (I say quick but debugging everything stream-related and
 * discovering one bug in Vapor in the process took me almost two days) that
 * demonstrates how we could hangle file uploads if needed.
 *
 * As we know, handling file uploads (and especially large video uploads) can be
 * a tricky process as we need to store the file in memory until we're ready to
 * save it – at least that's how it is in several languages and frameworks, and
 * how it was the case in Vapor 2.
 *
 * This demo shows that we can for these large file uploads use chunked
 * transfer. Client-side JavaScript (in this demo, Resumable.js[1] was used, and
 * configured with following configuration:
 *
 * {
 *     target: 'http://localhost:8080/api/uploads',
 *     chunkSize: 5245000, <- big enough for Cloudinary to accept, small enough for Vapor to not discard
 *     simultaneousUploads: 1,
 *     forceChunkSize: true <- necessary for Cloudinary, last chunk must be smaller than previous chunks
 * }
 *
 * This demo shows how Vapor passes the file chunks to Cloudinary to finally
 * store them. This approach is necessary in case we opt in for using PaaS
 * hosting solution such as Heroku or Vapor Cloud, or in general is wanted when
 * running in containerized environment. The code is not meant to be 100%
 * pretty, it's mostly a proof-of-concept.
 *
 * Making this work at all was made difficult due to bug in Vapor's multipart
 * package (I already voiced my concerns on relevant bug, referenced below) that
 * I had to work around after finally discovering it. To even discover it, it
 * was necessary to install local proxy to hijack all network traffic, install
 * official Cloudinary's Ruby client/library, hack the client to accept proxy's
 * fake SSL certificate and then observe what kind of requests does the official
 * library perform while mimicking them in Vapor. Unfortunately, all this was
 * necessary due to both the bug mentioned before and Cloudinary's
 * less-than-ideal state of documentation.
 *
 * [1]: http://www.resumablejs.com/
 */

struct UploadsController: RouteCollection {
    func boot(router: Router) throws {
        let uploadsRoute = router.grouped("api", "uploads")

        uploadsRoute.post(use: uploadHandler)
    }

    struct UploadRequest: Content {
        var file: File
    }

    struct ReuploadRequest: Content {
        var file: File
        var uploadPreset: String
        var publicId: String

        // FIXME: Ugly hack to circumvent bad issue in Multipart: vapor/multipart#22
        enum CodingKeys: String, CodingKey {
            case file = "\"file\""
            case uploadPreset = "\"upload_preset\""
            case publicId = "\"public_id\""
        }
    }

    func uploadHandler(_ req: Request) throws -> Future<HTTPStatus> {
        guard
            let identifier = req.query[String.self, at: "resumableIdentifier"],
            let currentChunk = req.query[Int.self, at: "resumableChunkNumber"],
            let usualChunkSize = req.query[Int.self, at: "resumableChunkSize"],
            let currentChunkSize = req.query[Int.self, at: "resumableCurrentChunkSize"],
            let totalSize = req.query[Int.self, at: "resumableTotalSize"]
        else {
            throw Abort(.badRequest)
        }

        let start = (currentChunk - 1) * usualChunkSize
        let end = start + currentChunkSize - 1

        return try req.content
            .decode(UploadRequest.self, maxSize: 100_000_000)
            .flatMap(to: HTTPStatus.self)
        { chunk in
            let client = try req.make(FoundationClient.self)
            let headers = HTTPHeaders([
                ("Content-Range", "bytes \(start)-\(end)/\(totalSize)"),
                // Identifier should be either better generated on client-side
                // or much better generated on server-side – that is, generate unique
                // identifier on first chunk only, then reuse it for other chunks
                ("X-Unique-Upload-Id", identifier),
            ])

            // Bucket name should be obtained from env variable
            return client.post("https://api.cloudinary.com/v1_1/dm112ndtb/video/upload",
                headers: headers,
                beforeSend:
            { request in
                // Upload preset should be obtained from env variable, publicId should obviously come
                // from somewhere else
                let body = ReuploadRequest(file: chunk.file, uploadPreset: "fwqfy6e4", publicId: "video.mp4")

                try request.content.encode(body, as: .formData)
            }).map { response in
                return .ok
            }
        }
    }
}
