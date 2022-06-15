// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutomatticTracksiOS",
    platforms: [.macOS(.v10_14), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AutomatticTracks",
            targets: ["AutomatticTracksEvents",
                      "AutomatticEncryptedLogs",
                      "AutomatticRemoteLogging",
                      "AutomatticExperiments",
                      "AutomatticCrashLoggingUI",
                      "AutomatticTracksModel",
                      "AutomatticTracksModelObjC",
                      "AutomatticTracksConstantsObjC",
                      "AutomatticTracks",
                     ]),

        // This target is seperated out to reduce the number of other dependencies included as part of the other targets.
        .library(
            name: "AutomatticEncryptedLogs",
            targets: ["AutomatticEncryptedLogs"]),

        // Xcode 12 has an issue where the first build after
        // cleaning fails if there is a dependency that vends
        // a binary .xcframework. We are working around this
        // on CI by first building this "_WorkaroundSPM"
        // target that _only_ builds that one dependency.
        // We ignore any failures when building this target.
        // Then we go on to build the actual product, which
        // builds correctly.
            .library(name: "_WorkaroundSPM",
                     targets: ["_WorkaroundSPM"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "Sentry", url: "https://github.com/getsentry/sentry-cocoa", from: "6.0.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(url: "https://github.com/squarefrog/UIDeviceIdentifier", from: "2.0.0"),
        .package(name: "OCMock", url: "https://github.com/erikdoe/ocmock", .branch("master")),
        .package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium", from: "0.9.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.


        // ExPlat experiments
        .target(
            name: "AutomatticExperiments",
            dependencies: ["AutomatticTracksModel"],
            path: "Sources/Experiments"),

        // Reporting events to the Tracks service
        .target(
            name: "AutomatticTracksEvents",
            dependencies: ["AutomatticTracksModel",
                           "AutomatticExperiments",
                           "AutomatticTracksEventsForSwift"],
            path: "Sources/Event Logging",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("../Model/ObjC")]),

        // Reporting events to the Tracks service
        //
        // This module offers a convenience incremental migration path
        // from ObjC to Swift for AutomatticTracksEvents.
        // Once all of the code is migrated to Swift we can just remove
        // AutomatticTracksEvents and rename this module to AutomatticTracksEvents
        //
        .target(
            name: "AutomatticTracksEventsForSwift",
            dependencies: ["AutomatticTracksModel"],
            path: "Sources/Event Logging (Swift)"
        ),

        // Uploading app logs and crash logs
        .target(
            name: "AutomatticRemoteLogging",
            dependencies: [
                "Sentry",
                "Sodium",
                "AutomatticTracksModel",
                "AutomatticTracksEvents",
                "AutomatticEncryptedLogs"
            ],
            path: "Sources/Remote Logging"),

        // Uploading app logs
        .target(
            name: "AutomatticEncryptedLogs",
            dependencies: [
                "Sodium",
                "AutomatticTracksConstantsObjC"
            ],
            path: "Sources/Encrypted Logs"),

        // UI for displaying crash logs
        .target(
            name: "AutomatticCrashLoggingUI",
            dependencies: ["AutomatticRemoteLogging"],
            path: "Sources/UI"),


        // A catch-all target for when you just want to import everything
        .target(
            name: "AutomatticTracks",
            dependencies: [
                "AutomatticExperiments",
                "AutomatticTracksEvents",
                "AutomatticRemoteLogging",
                "AutomatticCrashLoggingUI",
                "AutomatticTracksModel",
                "AutomatticTracksModelObjC"
            ],
            path: "Sources/AutomatticTracks",
            exclude: ["AutomatticTracks.h"]
        ),

        // Shared code used by multiple targets
        .target(
            name: "AutomatticTracksModelObjC",
            dependencies: [
                "UIDeviceIdentifier",
                "AutomatticTracksConstantsObjC"
            ],
            path: "Sources/Model/ObjC/Common",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("../../Event Logging/private")]),
        .target(
            name: "AutomatticTracksConstantsObjC",
            dependencies: [],
            path: "Sources/Model/ObjC/Constants",
            publicHeadersPath: ".",
            cSettings: []),
        .target(
            name: "AutomatticTracksModel",
            dependencies: ["AutomatticTracksModelObjC", "Sentry"],
            path: "Sources/Model/Swift"),

        // Tests
        .testTarget(
            name: "AutomatticTracksTests",
            dependencies: [
                "AutomatticTracks",
                "AutomatticTracksEvents",
                "AutomatticTracksModel",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            path: "Tests",
            exclude: ["Tests/ObjC"],
            resources: [.process("Mock Data")]),

            .testTarget(
                name: "AutomatticTracksTestsObjC",
                dependencies: ["AutomatticTracksEvents",
                               "OCMock"
                              ],
                path: "Tests/Tests/ObjC"),

            .target(
                name: "_WorkaroundSPM",
                dependencies: ["Sodium"],
                path: "Sources/Workaround-SPM")

    ]
)
