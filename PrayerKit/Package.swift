// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrayerKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PrayerKit",
            targets: ["PrayerKit"]
        )
    ],
    targets: [
        .target(
            name: "PrayerKit",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "PrayerKitTests",
            dependencies: ["PrayerKit"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
