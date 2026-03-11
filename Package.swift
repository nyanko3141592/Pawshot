// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pawshot",
    platforms: [
        .macOS(.v13),
    ],
    targets: [
        .executableTarget(
            name: "Pawshot",
            path: "Pawshot",
            exclude: ["Info.plist", "Pawshot.entitlements"],
            resources: [
                .process("Resources/Assets.xcassets"),
            ]
        ),
        .testTarget(
            name: "PawshotTests",
            dependencies: ["Pawshot"],
            path: "PawshotTests"
        ),
    ]
)
