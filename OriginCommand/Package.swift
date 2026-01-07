// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OriginCommand",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OriginCommand",
            targets: ["OriginCommand"]
        )
    ],
    targets: [
        .target(
            name: "OriginCommand",
            path: "Sources"
        )
    ]
)
