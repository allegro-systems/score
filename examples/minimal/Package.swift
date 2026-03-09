// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Minimal",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "Minimal",
            dependencies: [
                .product(name: "ScoreRuntime", package: "Score")
            ],
            path: "Sources"
        )
    ]
)
