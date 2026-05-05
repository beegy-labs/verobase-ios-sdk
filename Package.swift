// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Verobase",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "Verobase", targets: ["Verobase"]),
    ],
    targets: [
        .target(
            name: "Verobase",
            path: "Sources/Verobase"
        ),

    ]
)
