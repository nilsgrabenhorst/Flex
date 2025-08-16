// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let targetSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .strictMemorySafety(),
]

let package = Package(
    name: "Flex",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v9), .macCatalyst(.v18)],
    products: [
        .library(
            name: "Flex",
            targets: ["Flex"]
        ),
        .library(
            name: "FlexClient",
            targets: ["FlexClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory.git", from: "2.5.3"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(path: "../Swings"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "FlexMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "Flex",
            dependencies: [
                "FlexMacros",
                .product(name: "FactoryKit", package: "Factory"),
                .product(name: "FoundationSwings", package: "Swings"),
            ],
            swiftSettings: targetSettings
        ),

        // A client of the library, which is able to use the macro in its own code.
        .target(name: "FlexClient", dependencies: ["Flex"], swiftSettings: targetSettings),
        
        // A test target used to develop the macro implementation.
        .testTarget(
            name: "FlexTests",
            dependencies: [
                "FlexMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: targetSettings
        ),
    ]
)
