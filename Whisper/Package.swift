// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Whisper",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(
            url: "https://github.com/google-gemini/generative-ai-swift",
            from: "0.5.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Whisper",
            dependencies: [
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ],
            path: "Sources/Whisper"
        ),
        .testTarget(
            name: "WhisperTests",
            dependencies: ["Whisper"],
            path: "Tests/WhisperTests"
        )
    ]
)
