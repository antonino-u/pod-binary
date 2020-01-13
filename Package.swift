// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pod-binary",
    products: [
        .library(name: "PodBinaryKit", targets: ["PodBinaryKit"]),
        .executable(name: "pod-binary", targets: ["pod-binary"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/antonino-u/xcframework.git", .branch("master")),
        .package(url: "https://github.com/Carthage/Commandant", from: "0.17.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "PodBinaryKit",
            dependencies: ["XCFrameworkKit", "Files"]),
        .target(
            name: "pod-binary",
            dependencies: ["PodBinaryKit", "Commandant"]),
        .testTarget(
            name: "pod-binaryTests",
            dependencies: ["pod-binary"]),
    ]
)
