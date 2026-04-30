// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PiBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PiBar",
            path: "Sources/PiBar"
        )
    ]
)
