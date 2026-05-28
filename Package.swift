// swift-tools-version:6.0
import PackageDescription

// Shared DTOs + domain enums, depended on by both shopflow-api (server) and the
// ShopFlow iOS app. Pure Swift, no Vapor/Fluent/SwiftData — so both sides import
// one canonical source of truth for status vocab and transition rules.
let package = Package(
    name: "shopflow-shared",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
    ],
    products: [
        .library(name: "ShopFlowShared", targets: ["ShopFlowShared"]),
    ],
    targets: [
        .target(
            name: "ShopFlowShared",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ShopFlowSharedTests",
            dependencies: ["ShopFlowShared"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
