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
        .library(
            name: "PryPro",
            targets: ["PryPro"]
        ),
    ],
    targets: [
        .target(
            name: "Pry"
        ),
        .target(
            name: "PryPro",
            dependencies: ["Pry"]
        ),
        .testTarget(
            name: "PryTests",
            dependencies: ["Pry", "PryPro"]
        ),
    ]
)
