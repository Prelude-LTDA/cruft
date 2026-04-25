// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Cruft",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "Cruft", targets: ["Cruft"])
    ],
    targets: [
        .executableTarget(
            name: "Cruft",
            path: "Sources/Cruft",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
