// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Pry",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Pry",
            targets: ["Pry"]
        ),
    ],
    targets: [
        .target(
            name: "Pry"
        ),
        .testTarget(
            name: "PryTests",
            dependencies: ["Pry"]
        ),
    ]
)
