// swift-tools-version: 6.1

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
            name: "Pry",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PryTests",
            dependencies: ["Pry"]
        ),
    ]
)
