// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MagSafeLEDSync",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .target(
            name: "SMCKit",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .executableTarget(
            name: "smc-write",
            dependencies: ["SMCKit"]
        ),
        .executableTarget(
            name: "MagSafeLEDSync",
            dependencies: ["SMCKit"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "MagSafeLEDSyncTests",
            dependencies: ["MagSafeLEDSync"]
        )
    ]
)
