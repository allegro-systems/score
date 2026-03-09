// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Commerce",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "Commerce",
            dependencies: [
                .product(name: "ScoreRuntime", package: "Score"),
                .product(name: "ScoreVendor", package: "Score"),
            ],
            path: "Sources"
        )
    ]
)
