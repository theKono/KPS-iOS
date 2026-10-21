// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KPS",
    defaultLocalization: "zh-Hant",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KPS",
            targets: ["KPS"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/scalessec/Toast-Swift.git", .upToNextMajor(from: "5.1.1")),
       .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.0.0")),
       .package(url: "https://github.com/devicekit/DeviceKit.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
       .package(url: "https://github.com/malcommac/SwiftRichString.git", .upToNextMajor(from: "3.7.2")),
       .package(url: "https://github.com/realm/realm-swift.git", .upToNextMajor(from: "20.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KPS",
            dependencies: [
                .product(name: "Moya", package: "Moya"),
                .product(name: "Toast", package: "Toast-Swift"),
                .product(name: "SnapKit", package: "SnapKit"),
                .product(name: "DeviceKit", package: "DeviceKit"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftRichString", package: "SwiftRichString"),
                .product(name: "RealmSwift", package: "realm-swift")
            ],
            path: "Sources/KPS",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "KPSTests",
            dependencies: ["KPS"],
            path: "Tests/KPSTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
