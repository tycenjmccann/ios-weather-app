// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WeatherApp",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "WeatherFeature", targets: ["WeatherFeature"]),
    ],
    targets: [
        .target(name: "WeatherFeature", path: "Sources/WeatherFeature"),
        .testTarget(name: "WeatherFeatureTests", dependencies: ["WeatherFeature"], path: "Tests/WeatherFeatureTests"),
    ]
)
