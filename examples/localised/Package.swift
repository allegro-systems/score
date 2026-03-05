// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Localised",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "Localised",
            dependencies: [
                .product(name: "Score", package: "Score"),
            ],
            path: "Sources"
        ),
    ]
)
