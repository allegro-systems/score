// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Score",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Score", targets: ["Score"]),
        .library(name: "ScoreCore", targets: ["ScoreCore"]),
        .library(name: "ScoreHTML", targets: ["ScoreHTML"]),
        .library(name: "ScoreCSS", targets: ["ScoreCSS"]),
        .library(name: "ScoreRouter", targets: ["ScoreRouter"]),
        .library(name: "ScoreRuntime", targets: ["ScoreRuntime"]),
        .library(name: "ScoreContent", targets: ["ScoreContent"]),
        .library(name: "ScoreAssets", targets: ["ScoreAssets"]),
        .library(name: "ScoreExtensions", targets: ["ScoreExtensions"]),
        .executable(name: "score", targets: ["ScoreCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/tuist/Noora", from: "0.55.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .macro(
            name: "ScoreMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "ScoreCore",
            dependencies: [
                "ScoreMacros",
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .target(name: "ScoreHTML", dependencies: ["ScoreCore"]),
        .target(name: "ScoreCSS", dependencies: ["ScoreCore"]),
        .target(
            name: "ScoreRouter",
            dependencies: [
                "ScoreCore",
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .target(
            name: "ScoreRuntime",
            dependencies: [
                "ScoreCore",
                "ScoreHTML",
                "ScoreCSS",
                "ScoreRouter",
                "ScoreAssets",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
            ],
            resources: [.copy("Resources")]
        ),
        .target(
            name: "ScoreContent",
            dependencies: [
                "ScoreCore",
                "ScoreHTML",
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .target(name: "ScoreAssets", dependencies: ["ScoreCore"]),
        .target(name: "ScoreExtensions", dependencies: ["ScoreCore", "ScoreRouter"]),
        .target(
            name: "Score",
            dependencies: [
                "ScoreCore", "ScoreHTML", "ScoreCSS", "ScoreRouter", "ScoreRuntime",
                "ScoreContent", "ScoreAssets", "ScoreExtensions",
            ]
        ),
        .executableTarget(
            name: "ScoreCLI",
            dependencies: [
                "Score",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Noora", package: "Noora"),
            ]
        ),
        .testTarget(name: "ScoreCLITests", dependencies: ["ScoreCLI"]),
        .testTarget(name: "ScoreCoreTests", dependencies: ["ScoreCore"]),
        .testTarget(name: "ScoreTests", dependencies: ["Score"]),
        .testTarget(name: "ScoreHTMLTests", dependencies: ["ScoreHTML"]),
        .testTarget(name: "ScoreCSSTests", dependencies: ["ScoreCSS"]),
        .testTarget(name: "ScoreRouterTests", dependencies: ["ScoreRouter"]),
        .testTarget(
            name: "ScoreRuntimeTests",
            dependencies: [
                "ScoreRuntime",
                "ScoreAssets",
                .product(name: "NIOEmbedded", package: "swift-nio"),
            ]
        ),
        .testTarget(name: "ScoreContentTests", dependencies: ["ScoreContent", "ScoreHTML"]),
        .testTarget(name: "ScoreAssetsTests", dependencies: ["ScoreAssets"]),
        .testTarget(name: "ScoreExtensionsTests", dependencies: ["ScoreExtensions"]),
    ]
)
