// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Docs",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Docs",
            dependencies: [
                .product(name: "Score", package: "Score"),
            ],
            path: "Sources"
        ),
    ]
)
