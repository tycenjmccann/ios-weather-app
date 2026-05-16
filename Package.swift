// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WeatherApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "WeatherApp",
            targets: ["WeatherApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "WeatherApp",
            path: "Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "WeatherAppTests",
            dependencies: [
                "WeatherApp",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
