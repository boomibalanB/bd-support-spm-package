// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BoldDeskSupportSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "BoldDeskSupportSDK",
            targets: ["BoldDeskSupportSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "3.1.4"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSVGCoder.git", from: "1.8.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.57.3"),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit.git", from: "4.2.10"),
    ],
    targets: [
        .target(
            name: "BoldDeskSupportSDK",
            dependencies: [
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "SDWebImageSVGCoder", package: "SDWebImageSVGCoder"),
                .product(name: "Sentry", package: "sentry-cocoa"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit"),
            ],
            path: "BoldDeskSupportSDK"
        )
    ]
)