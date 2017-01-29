import PackageDescription

let package = Package(
    name: "Coroutine",
    dependencies: [
        .Package(url: "https://github.com/windoze/swift-context.git", majorVersion: 1)
    ]
)
