// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "qae",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.7")
    ],
    targets: [
        .executableTarget(
            name: "qae",
            dependencies: ["SwiftTerm"],
            path: "Sources/qae",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
