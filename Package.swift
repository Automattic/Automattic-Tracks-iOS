// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Automattic-Tracks-iOS",
    platforms: [.macOS(.v10_14), .iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Automattic-Tracks-iOS",
            targets: ["AutomatticTracksEventLogging",
                      "AutomatticRemoteLogging",
                      "AutomatticABTesting",
                      "AutomatticCrashLoggingUI"
            ]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.0.0"),
        .package(name: "Sentry", url: "https://github.com/getsentry/sentry-cocoa", from: "6.0.0"),
        .package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium", from: "0.9.1"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(url: "https://github.com/squarefrog/UIDeviceIdentifier", from: "1.7.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AutomatticTracksModelObjC",
            dependencies: ["UIDeviceIdentifier", "CocoaLumberjack"],
            path: "Automattic-Tracks-iOS/Model/ObjC",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("../../Event Logging/private")]),
        .target(
            name: "AutomatticTracksModel",
            dependencies: ["AutomatticTracksModelObjC", "Sentry",
                           "CocoaLumberjack"
            ],
            path: "Automattic-Tracks-iOS/Model/Swift"),
        

        .target(
            name: "AutomatticTracksEventLogging",
            dependencies: ["AutomatticTracksModel"],
            path: "Automattic-Tracks-iOS/Event Logging",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("private")]),



        .target(
            name: "AutomatticCrashLoggingObjC",
            dependencies: ["Sentry"],
            path: "Automattic-Tracks-iOS/Remote Logging/Crash Logging/ObjC",
            publicHeadersPath: "."),

        .target(
            name: "AutomatticRemoteLogging",
            dependencies: ["Sentry",
                           "Sodium",
                           .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                           "AutomatticTracksModel",
                           "AutomatticTracksEventLogging",
                          "AutomatticCrashLoggingObjC"],
            path: "Automattic-Tracks-iOS/Remote Logging",
            exclude: ["Crash Logging/ObjC"]),


        .target(
            name: "AutomatticABTesting",
            dependencies: [.product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")],
            path: "Automattic-Tracks-iOS/ABTesting"
        ),

        .target(
            name: "AutomatticCrashLoggingUI",
            dependencies: ["AutomatticRemoteLogging"],
            path: "Automattic-Tracks-iOS/UI"),

    ]
)
