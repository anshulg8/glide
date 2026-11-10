// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Glide",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Glide",
            targets: ["Glide"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Glide",
            dependencies: [],
            path: "Sources/Glide"
        )
    ]
)

