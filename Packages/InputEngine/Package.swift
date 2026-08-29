// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "InputEngine",
    platforms: [.macOS(.v26)],
    products: [.library(name: "InputEngine", targets: ["InputEngine"])],
    targets: [
        .target(name: "InputEngine"),
        .testTarget(name: "InputEngineTests", dependencies: ["InputEngine"]),
    ]
)
