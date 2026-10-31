// swift-tools-version: 5.9
// StoreCore — the UIKit-free heart of NUTM Campus Store: models, validation rules,
// the auth service, a fake server and the two ViewModels (Sign in, Sign up).
// No UIKit here, so every rule is unit-tested in milliseconds (⌘U, or `swift test`).
import PackageDescription

let package = Package(
    name: "StoreCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "StoreCore", targets: ["StoreCore"]),
    ],
    targets: [
        .target(name: "StoreCore"),
        .testTarget(name: "StoreCoreTests", dependencies: ["StoreCore"]),
    ]
)
