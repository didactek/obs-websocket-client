// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "obs-websocket-client",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "OBSWebsocket", targets: ["OBSWebsocket"]),
        .library(name: "OBSAsyncAPI", targets: ["OBSAsyncAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/didactek/deft-log.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "SampleClient",
            dependencies: [
                "OBSAsyncAPI",
            ]),
        .target(
            name: "OBSWebsocket",
            dependencies: [
                "GenerateOBSWebServices",
            ]),
        .target(
            name: "OBSAsyncAPI",
            dependencies: [
                "OBSWebsocket",
                "GenerateOBSWebServices",
                .product(name: "DeftLog", package: "deft-log"),
            ]),
        .executableTarget(
            name: "OBSProtocolConverter",
            dependencies: [],
            exclude: ["protocol.json"]
        ),
        .plugin(
            name: "GenerateOBSWebServices",
            capability: .buildTool(),
            dependencies: ["OBSProtocolConverter"]
        ),
        .plugin(
            name: "GenerateOBSClientDocumentation",
            capability: .command(
                // Note: do not use .documentationGeneration to describe intent.
                // .documentationGeneration hardcodes the generate-documentation
                // verb, which is a convention adopted by the swift-docc-plugin.
                intent: .custom(
                    verb: "extract-obsclient-docc-extension",
                    description: "Create a documentation topic extension in OBSAsyncAPI to organize OBSClient functions by category in protocol.json"),
                permissions: [
                    .writeToPackageDirectory(reason: "Generate/refresh OBSAsyncAPI DocC topics for OBSClient.md")
                ]
            ),
            dependencies: ["OBSProtocolConverter"]
        ),
    ]
)
