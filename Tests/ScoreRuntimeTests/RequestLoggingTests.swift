import Foundation
import HTTPTypes
import ScoreCore
import Testing

@testable import ScoreRuntime

@Suite("RequestLoggingMiddleware")
struct RequestLoggingTests {
    @Test("Logs correct format: METHOD path status durationms")
    func logsCorrectFormat() {
        let logged = LockedValue<String?>(nil)
        let middleware = RequestLoggingMiddleware(logHandler: { message in
            logged.withLock { $0 = message }
        })

        let response = Response.text("OK")
        let result = middleware.handle(
            method: .get,
            path: "/hello",
            response: response,
            duration: 0.042
        )

        #expect(logged.withLock { $0 } == "GET /hello 200 42ms")
        #expect(result.status.code == 200)
    }

    @Test("Logs 404 responses")
    func logs404() {
        let logged = LockedValue<String?>(nil)
        let middleware = RequestLoggingMiddleware(logHandler: { message in
            logged.withLock { $0 = message }
        })

        let response = Response.text("Not Found", status: .notFound)
        _ = middleware.handle(
            method: .get,
            path: "/missing",
            response: response,
            duration: 0.005
        )

        #expect(logged.withLock { $0 } == "GET /missing 404 5ms")
    }

    @Test("Logs 500 responses")
    func logs500() {
        let logged = LockedValue<String?>(nil)
        let middleware = RequestLoggingMiddleware(logHandler: { message in
            logged.withLock { $0 = message }
        })

        let response = Response.text("Error", status: .internalServerError)
        _ = middleware.handle(
            method: .post,
            path: "/api/data",
            response: response,
            duration: 0.123
        )

        #expect(logged.withLock { $0 } == "POST /api/data 500 123ms")
    }
}
