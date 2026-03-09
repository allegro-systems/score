// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "App",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "ScoreRuntime", package: "Score"),
                .product(name: "ScoreContent", package: "Score"),
                .product(name: "ScoreAuth", package: "Score"),
                .product(name: "ScoreVendor", package: "Score"),
            ],
            path: "Sources"
        )
    ]
)
