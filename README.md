# Globalmoji

A native, open-source macOS emoji picker in the style of Slack/Discord (and [Rocket](https://matthewpalmer.net/rocket/)). Type `:` followed by a name in any app to search emoji, GIFs and ASCII emoticons and insert them inline.

**Status:** early development — see [PLAN.md](PLAN.md).

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26 (to build)

## Installing

Download the latest DMG from [Releases](https://github.com/bevanjkay/globalmoji/releases) and drag Globalmoji to Applications. Builds are not yet notarised, so on first launch either right-click › Open, or run:

```sh
xattr -d com.apple.quarantine /Applications/Globalmoji.app
```

On launch, grant **Input Monitoring** and **Accessibility** when prompted (both are required — see below), then type `:` and a few letters in any text field.

### Permissions look on but nothing happens?

macOS ties Accessibility and Input Monitoring grants to the exact build that requested them. Because Globalmoji is not yet signed with a Developer ID, every update is a "new" binary and the old grants silently stop applying while System Settings still shows them on. Use **Reset permissions and try again** in the setup window (menu bar › Permissions…), or run:

```sh
tccutil reset Accessibility me.bevankay.globalmoji
tccutil reset ListenEvent me.bevankay.globalmoji
```

then relaunch Globalmoji and grant both again.

## Usage

- `:smi` → picker opens near the caret; arrow keys move, `↩` inserts, `esc` closes.
- `⇥` / `⇧⇥` switch between Emoji, GIF and ASCII modes.
- GIF search needs a GIPHY API key: release builds include a shared key, or paste your own under Settings › GIFs.
- Settings › Apps controls where the trigger is active (deny-list or allow-list by bundle ID).

## Building

```sh
make generate   # regenerate Globalmoji.xcodeproj from project.yml (requires xcodegen)
make build
make test
make package    # Release archive → dist/Globalmoji-<version>.dmg and .zip
```

Releases are cut by pushing a `v*` tag; `.github/workflows/release.yml` builds, signs, notarises (when the Developer ID and App Store Connect secrets are configured) and publishes the GitHub Release. Set a `GIPHY_API_KEY` repository secret to bake a shared key into release builds.

Globalmoji needs the **Accessibility** and **Input Monitoring** permissions to observe the `:` trigger and insert text. It runs outside the App Sandbox and is not distributed via the Mac App Store.

## License

MIT — see [LICENSE](LICENSE).
