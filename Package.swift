// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SpotiWidget",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SpotiWidget",
            path: "Sources/SpotiWidget"
        )
    ]
)
