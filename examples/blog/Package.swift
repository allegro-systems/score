// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Blog",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "Blog",
            dependencies: [
                .product(name: "ScoreRuntime", package: "Score"),
                .product(name: "ScoreContent", package: "Score"),
            ],
            path: "Sources"
        )
    ]
)
