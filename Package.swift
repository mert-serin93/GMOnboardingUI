// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GMOnboardingUI",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GMOnboardingUI",
            targets: ["GMOnboardingUI"]),
    ],
    dependencies: [
        .package(name: "SwiftKeychainWrapper", url: "https://github.com/jrendel/SwiftKeychainWrapper", .upToNextMajor(from: "4.0.1")),
        .package(name: "Kingfisher", url: "https://github.com/onevcat/Kingfisher", .upToNextMajor(from: "8.1.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GMOnboardingUI", dependencies: [
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ]),
    ],
    swiftLanguageModes: [.v5]
)
