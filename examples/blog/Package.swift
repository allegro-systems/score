// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Blog",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "Blog",
            dependencies: [
                .product(name: "Score", package: "Score")
            ],
            path: "Sources",
            resources: [.process("Content/")]
        )
    ]
)
