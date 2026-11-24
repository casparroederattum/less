// swift-tools-version:5.9
// Swift Package instead of an Xcode project: it builds with the Command Line
// Tools alone, so nobody needs a 10 GB download to work on Less.
import PackageDescription

let package = Package(
    name: "Less",
    // macOS 14 is the oldest system whose SwiftUI has everything the views use.
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Less",
            path: "Sources/Less",
            // Browser and Screen Time history live in SQLite files.
            linkerSettings: [.linkedLibrary("sqlite3")]
        )
    ]
)
