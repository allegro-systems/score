import Testing

@testable import ScoreVendor

private struct TestVendor: Vendor {
    var routes: [Route] {
        [
            Route(method: .post, path: "/test/webhook"),
            Route(method: .get, path: "/test/status"),
        ]
    }
}

@Test func vendorExposesRoutes() {
    let vendor = TestVendor()
    #expect(vendor.routes.count == 2)
    #expect(vendor.routes[0].path == "/test/webhook")
    #expect(vendor.routes[1].path == "/test/status")
}
