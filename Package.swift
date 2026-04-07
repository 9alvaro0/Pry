// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WarwareInspector",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "WarwareInspector",
            targets: ["WarwareInspector"]
        ),
    ],
    targets: [
        .target(
            name: "WarwareInspector"
        ),
    ]
)
