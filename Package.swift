// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LeakDetect",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "leakDetect", targets: ["LeakDetect"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "508.0.0"
        ),

        .package(
            url: "https://github.com/yume190/TypeFill",
            from: "0.4.9"
        ),
//        .package(path: "../TypeFill"),

        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.34.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.1"),
        .package(url: "https://github.com/zonble/HumanString.git", from: "0.1.1"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.5"),
        
        
    ],
    targets: [
        .executableTarget(
            name: "LeakDetect",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SKClient", package: "TypeFill"),
                "LeakDetectKit",
                "PathKit",
                "Yams",
            ]
        ),

        // MARK: Frameworks

        .target(
            name: "LeakDetectKit",
            dependencies: [
                "Rainbow",
                "PathKit",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SKClient", package: "TypeFill"),
            ]
        ),

        // MARK: Tests

        .testTarget(
            name: "LeakDetectTests",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SKClient", package: "TypeFill"),
                "LeakDetectKit",
                "HumanString",
            ],
            resources: [
                .copy("Resource"),
            ]
        ),
    ]
)
