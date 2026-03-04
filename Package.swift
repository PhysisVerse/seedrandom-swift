// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SeedRandom",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "SeedRandom",
            targets: ["SeedRandom"]
        )
    ],
    targets: [
        .target(
            name: "SeedRandom",
            dependencies: []
        ),
        .testTarget(
            name: "SeedRandomTests",
            dependencies: ["SeedRandom"]
        )
    ]
)
