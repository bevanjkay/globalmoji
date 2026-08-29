// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PickerCore",
    platforms: [.macOS(.v26)],
    products: [.library(name: "PickerCore", targets: ["PickerCore"])],
    targets: [
        .target(name: "PickerCore"),
        .testTarget(name: "PickerCoreTests", dependencies: ["PickerCore"]),
    ]
)
