// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AirPodsPosture",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .executable(name: "AirPodsPosture", targets: ["AirPodsPosture"]),
        .library(name: "AirPodsCore", targets: ["AirPodsCore"]),
        .library(name: "AirPodsIOS", targets: ["AirPodsIOS"]),
        .library(name: "AirPodsWatch", targets: ["AirPodsWatch"])
    ],
    targets: [
        .target(
            name: "AirPodsCore",
            path: "Sources/AirPodsCore"
        ),
        .executableTarget(
            name: "AirPodsPosture",
            dependencies: [
                "AirPodsCore"
            ],
            path: "Sources/AirPodsPosture",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "AirPodsIOS",
            dependencies: [
                "AirPodsCore"
            ],
            path: "Sources/AirPodsIOS"
        ),
        .target(
            name: "AirPodsWatch",
            dependencies: [
                "AirPodsCore"
            ],
            path: "Sources/AirPodsWatch"
        ),
        .testTarget(
            name: "AirPodsPostureTests",
            dependencies: ["AirPodsPosture"]
        )
    ]
)
