# Agent notes

## Build & test
- `make generate` regenerates `Globalmoji.xcodeproj` from `project.yml` (XcodeGen). Commit both after changing `project.yml`.
- `make build` builds the app; `make test` runs the SwiftPM package tests (`Packages/PickerCore`, `Packages/InputEngine`).
- `make lint` runs `swiftformat --lint` and `swiftlint`.
- Core logic lives in the local SwiftPM packages; keep AppKit/SwiftUI out of `PickerCore` so it stays testable with `swift test`.

## Conventions
- Swift 6 strict concurrency; new types should be `Sendable` or isolated to `@MainActor`.
- Minimum macOS 26; bundle ID `me.bevankay.globalmoji`.
- Per-app rules, settings, recents and favourites persist as Codable JSON under `~/Library/Application Support/Globalmoji/`.

## Permissions when testing locally
- Event taps need Input Monitoring; insertion needs Accessibility. macOS ties grants to the code signature, so sign dev builds with a stable identity (see `CODE_SIGN_IDENTITY` in `project.yml`) or you'll re-grant on every rebuild.
