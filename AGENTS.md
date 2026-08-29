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

## Emoji data
- `make emoji-data` regenerates `Packages/PickerCore/Sources/PickerCore/Resources/emoji.json` from emojibase-data (needs `node` ≥ 18, no npm install). Commit the regenerated file; tests assert on specific entries (`1F600`, `1F44B`, `1F44D`).
- Emoji `character` strings include variation selectors as emitted by emojibase; compare by `id` (hexcode) in tests.

## Input engine
- `TriggerController` is pure logic and unit-tested with `KeyEvent`s; `KeyEventTap`/`TextInserter` touch CoreGraphics and can only be exercised by running the app with permissions granted.
- Synthesised events carry `KeyEventTap.syntheticMarker` in `eventSourceUserData`; the tap ignores them so pasted/typed output never re-enters the trigger state machine.

## Releases
- `Scripts/package.sh [version]` archives, ad-hoc signs (override with `CODE_SIGN_IDENTITY`), and writes DMG/zip/SHA256SUMS to `dist/`. `release.yml` runs it on `v*` tags and publishes a GitHub Release; notarisation is not wired up until a Developer ID exists.
