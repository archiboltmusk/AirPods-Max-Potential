// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AirPodsPosture",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "AirPodsPosture",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
