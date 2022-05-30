// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#warning("todo isBuildStatic & isXCode")
//ProcessInfo.processInfo.environment[""] != nil
let isBuildStatic = true
let isXCode = true
let linkerSetting: [LinkerSetting] = [
    /// when use xcode archive
    .unsafeFlags([
        "-Xlinker", "-rpath",
        "-Xlinker", "@executable_path/Frameworks",
    ], .when(platforms: [.macOS]))
]
let staticTarget: [Target] = [
    .executableTarget(
        name: "LeakDetect",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "SourceKittenFramework", package: "SourceKitten"),
            .product(name: "SKClient", package: "TypeFill"),
            "LeakDetectKit",
            "lib_InternalSwiftSyntaxParser",
        ],
        linkerSettings: [
            .unsafeFlags([
                "-Xlinker", "-dead_strip_dylibs",
            ], .when(platforms: [.macOS]))
        ]
    ),
    // MARK: Swift Syntax
    // from https://github.com/krzysztofzablocki/Sourcery/blob/master/Package.swift
    // Pass `-dead_strip_dylibs` to ignore the dynamic version of `lib_InternalSwiftSyntaxParser`
    // that ships with SwiftSyntax because we want the static version from
    // `StaticInternalSwiftSyntaxParser`.
    .binaryTarget(
        name: "lib_InternalSwiftSyntaxParser",
        url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.6/lib_InternalSwiftSyntaxParser.xcframework.zip",
        checksum: "88d748f76ec45880a8250438bd68e5d6ba716c8042f520998a438db87083ae9d"
    ),
]
let dynamicTarget: [Target] = [
    .executableTarget(
        name: "LeakDetect",
        dependencies: [
           .product(name: "ArgumentParser", package: "swift-argument-parser"),
           .product(name: "SourceKittenFramework", package: "SourceKitten"),
           .product(name: "SKClient", package: "TypeFill"),
            "LeakDetectKit",
        ],
        linkerSettings: isXCode ? linkerSetting : []
    ),
]
let target: [Target] = isBuildStatic ? staticTarget : dynamicTarget

let package = Package(
    name: "LeakDetect",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "leakDetect", targets: ["LeakDetect"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "SwiftSyntax",
            url: "https://github.com/apple/swift-syntax.git",
            .exact("0.50600.1")
        ),
        
        .package(
            name: "TypeFill",
            url: "https://github.com/yume190/TypeFill",
            from: "0.4.1"
        ),
        
        .package(url: "https://github.com/jpsim/SourceKitten", from: "0.32.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.1"),
        .package(url: "https://github.com/zonble/HumanString.git", from: "0.1.1"),

    ],
    targets: [
        // MARK: Frameworks
        .target(
            name: "LeakDetectKit",
            dependencies: [
                "Rainbow",
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "SwiftSyntaxParser", package: "SwiftSyntax"),

                .product(name: "SKClient", package: "TypeFill"),
            ]
        ),
        
        // MARK: Tests
        .testTarget(
            name: "LeakDetectTests",
            dependencies: [
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
                .product(name: "SKClient", package: "TypeFill"),
                "LeakDetectKit",
                "HumanString",
            ],
            resources: [
                .copy("Resource")
            ]
        ),
    ] + target
)
