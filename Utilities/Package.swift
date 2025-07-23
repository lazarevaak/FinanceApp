// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PieChart",
            targets: ["PieChart"]
        ),
    ],
    targets: [
        .target(
            name: "PieChart",
            path: "Sources/PieChart"
        ),
    ]
)
