// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FormattableTextView",
    platforms: [
            .iOS(.v9),
        ],
    products: [
        // The external product of our package is an importable
        // library that has the same name as the package itself:
        .library(
            name: "FormattableTextView",
            targets: ["FormattableTextView"]
        )
    ],
    targets: [
        // Our package contains two targets, one for our library
        // code, and one for our tests:
        .target(name: "FormattableTextView", path: "FormattableTextView", exclude: ["Info.plist"])
    ]
)
