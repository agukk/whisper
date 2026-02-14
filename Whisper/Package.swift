// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Whisper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Whisper",
            path: "Sources/Whisper"
        ),
        .testTarget(
            name: "WhisperTests",
            dependencies: ["Whisper"],
            path: "Tests/WhisperTests"
        )
    ]
)
