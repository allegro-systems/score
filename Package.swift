// swift-tools-version: 6.3

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
        .library(name: "ScoreUI", targets: ["ScoreUI"]),
        .library(name: "ScoreAssets", targets: ["ScoreAssets"]),
        .library(name: "ScoreData", targets: ["ScoreData"]),
        .library(name: "ScoreAuth", targets: ["ScoreAuth"]),
        .library(name: "ScoreTesting", targets: ["ScoreTesting"]),
        .executable(name: "score", targets: ["ScoreCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/tuist/Noora", from: "0.55.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "git@github.com:allegro-systems/stage.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.4.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.1.0"),
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
                .product(name: "StageKit", package: "Stage"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .target(
            name: "ScoreContent",
            dependencies: [
                "ScoreCore",
                "ScoreHTML",
                "ScoreCSS",
                "ScoreUI",
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .target(
            name: "ScoreUI",
            dependencies: [
                "ScoreCore",
                "ScoreHTML",
                "ScoreCSS",
                "ScoreRuntime",
            ]
        ),
        .target(name: "ScoreAssets", dependencies: ["ScoreCore"]),
        .target(name: "ScoreData", dependencies: ["ScoreCore"]),
        .target(name: "ScoreAuth", dependencies: ["ScoreCore", "ScoreRuntime"]),
        .target(
            name: "ScoreTesting",
            dependencies: [
                "ScoreCore",
                "ScoreHTML",
                "ScoreCSS",
                "ScoreRuntime",
            ]
        ),
        .target(
            name: "Score",
            dependencies: [
                "ScoreCore", "ScoreHTML", "ScoreCSS", "ScoreRouter", "ScoreRuntime",
                "ScoreContent", "ScoreUI", "ScoreAssets", "ScoreData", "ScoreAuth",
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
            ]
        ),
        .testTarget(name: "ScoreContentTests", dependencies: ["ScoreContent", "ScoreHTML"]),
        .testTarget(name: "ScoreAssetsTests", dependencies: ["ScoreAssets"]),
        .testTarget(name: "ScoreDataTests", dependencies: ["ScoreData"]),
        .testTarget(name: "ScoreAuthTests", dependencies: ["ScoreAuth"]),
        .testTarget(name: "ScoreTestingTests", dependencies: ["ScoreTesting"]),
    ]
)
