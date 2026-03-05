// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Minimal",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Minimal",
            dependencies: [
                .product(name: "Score", package: "Score"),
            ],
            path: "Sources"
        ),
    ]
)
