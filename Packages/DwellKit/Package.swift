// swift-tools-version: 6.2
import PackageDescription

// DwellCore is plain Foundation: the models, the product rules and the sample data.
// It builds and tests anywhere, including Linux (`swift test`).
//
// DwellUI is SwiftUI: tokens and shared components. It only builds on Apple platforms,
// so it is left out when the manifest is read on Linux.

let approachableConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

var products: [Product] = [
    .library(name: "DwellCore", targets: ["DwellCore"]),
]

var targets: [Target] = [
    .target(
        name: "DwellCore",
        swiftSettings: approachableConcurrency
    ),
    .testTarget(
        name: "DwellCoreTests",
        dependencies: ["DwellCore"],
        swiftSettings: approachableConcurrency
    ),
]

#if !os(Linux)
products.append(.library(name: "DwellUI", targets: ["DwellUI"]))
targets.append(
    .target(
        name: "DwellUI",
        dependencies: ["DwellCore"],
        resources: [.process("Resources")],
        swiftSettings: approachableConcurrency + [.defaultIsolation(MainActor.self)]
    )
)
#endif

let package = Package(
    name: "DwellKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: products,
    targets: targets
)
