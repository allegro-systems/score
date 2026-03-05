// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Marketing",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Marketing",
            dependencies: [
                .product(name: "Score", package: "Score"),
            ],
            path: "Sources"
        ),
    ]
)
