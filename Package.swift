// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "grinsh",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "grinsh",
            targets: ["grinsh"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "grinsh",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources"
        )
    ]
)
