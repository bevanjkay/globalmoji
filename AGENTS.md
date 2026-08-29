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
- Event taps need Input Monitoring; insertion needs Accessibility. TCC pins grants to the cdhash of ad-hoc signed builds, so every rebuild/reinstall silently invalidates them while System Settings still shows them on. Fix: `tccutil reset Accessibility me.bevankay.globalmoji && tccutil reset ListenEvent me.bevankay.globalmoji`, relaunch, re-grant (the setup window has a button for this). Verify with `sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db"` (csreq cdhash) vs `codesign -d -r- Globalmoji.app`. A stable signing identity is the real cure.

## Assets
- `make icon` rebuilds `App/Assets.xcassets/AppIcon.appiconset` from `Design/app-icon-source.png` via `Scripts/make-appiconset.py` (needs Pillow + numpy). Replace the source artwork, not the generated PNGs; the script cuts the squircle out of the white background and places it on Apple's 1024/824 icon grid.

## Emoji data
- `make emoji-data` regenerates `Packages/PickerCore/Sources/PickerCore/Resources/emoji.json` from emojibase-data (needs `node` ≥ 18, no npm install). Commit the regenerated file; tests assert on specific entries (`1F600`, `1F44B`, `1F44D`).
- Emoji `character` strings include variation selectors as emitted by emojibase; compare by `id` (hexcode) in tests.

## Input engine
- `TriggerController` is pure logic and unit-tested with `KeyEvent`s; `KeyEventTap`/`TextInserter` touch CoreGraphics and can only be exercised by running the app with permissions granted.
- Synthesised events carry `KeyEventTap.syntheticMarker` in `eventSourceUserData`; the tap ignores them so pasted/typed output never re-enters the trigger state machine.

## Releases
- `Scripts/package.sh [version]` archives, ad-hoc signs (override with `CODE_SIGN_IDENTITY`), and writes DMG/zip/SHA256SUMS to `dist/`. `release.yml` runs it on `v*` tags and publishes a GitHub Release; notarisation is not wired up until a Developer ID exists.
- Only `keyDown` uses an active tap; mouse buttons are observed with a listen-only tap so a stalled process can never block clicks. Never run two instances with taps (the app quits if one is already running) — an earlier double launch froze all input.
