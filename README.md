<h1 align="center">Globalmoji</h1>

<p align="center">Type <code>:</code> for emoji, GIFs and kaomoji — in any Mac app.</p>

<p align="center">
  <a href="https://github.com/bevanjkay/globalmoji/releases/latest">Download</a> ·
  <a href="https://bevanjkay.github.io/globalmoji/">Website</a> ·
  <a href="https://github.com/bevanjkay/globalmoji/issues">Report an issue</a>
</p>

Globalmoji is a free, open-source emoji picker for macOS in the style of Slack and Discord. Type `:` followed by a name in any text field — Slack, Mail, Notes, browsers, terminals — and the picker appears beside your caret so you can insert emoji, GIFs and ASCII faces inline.

## Install

```sh
brew install --cask bevanjkay/tap/globalmoji
```

Or download the DMG from [Releases](https://github.com/bevanjkay/globalmoji/releases/latest) and drag Globalmoji to Applications. Requires **macOS 26 (Tahoe)** or later. Builds are signed with Developer ID and notarised by Apple.

On first launch, grant **Input Monitoring** and **Accessibility** when prompted. Both are required: one lets Globalmoji see the `:` you type, the other lets it insert your pick.

## Using it

Type `:` and a few letters in any text field:

| Key | Action |
| --- | --- |
| `↑` `↓` `←` `→` | Move the selection |
| `↩` | Insert the selected item |
| `⇥` / `⇧⇥` | Switch between Emoji, GIF and ASCII |
| `esc` | Close the picker |

- **Emoji** — 1,900+ emoji searchable by name, keyword or Slack/GitHub shortcode. Recently used emoji are boosted in results.
- **GIF** — GIPHY search. GIFs are pasted as image data with the link as a fallback, so Slack and Discord get the image and plain-text apps get the link.
- **ASCII** — a curated set of kaomoji like `¯\_(ツ)_/¯`.

Globalmoji lives in the menu bar. Open **Settings** from there to:

- change the trigger key (`:`, `;`, `/`, `\` or `` ` ``) and how many characters you type before the picker opens
- pick a default skin tone
- choose whether items are inserted by pasting or by typing
- launch Globalmoji at login
- add your own GIPHY API key (release builds include a shared one, which is rate limited)
- turn Globalmoji off in specific apps, or limit it to only the apps you choose

Your settings and recents stay on your Mac, in `~/Library/Application Support/Globalmoji/`. Nothing is sent anywhere except GIF searches to GIPHY.

## Troubleshooting

**The picker doesn't appear, but permissions look enabled.** macOS ties Accessibility and Input Monitoring grants to the exact build that requested them, so an update can silently invalidate them while System Settings still shows them on. Use **Reset permissions and try again** in the setup window (menu bar › Permissions…), or run:

```sh
tccutil reset Accessibility me.bevankay.globalmoji
tccutil reset ListenEvent me.bevankay.globalmoji
```

then relaunch Globalmoji and grant both again.

**GIF search returns nothing.** The shared API key may be rate limited — add your own free key under Settings › GIFs.

Still stuck? [Open an issue](https://github.com/bevanjkay/globalmoji/issues).

## Contributing

Globalmoji is written in Swift with SwiftUI and AppKit. Building needs Xcode 26:

```sh
make generate   # regenerate the Xcode project (requires xcodegen)
make build
make test
```

See [AGENTS.md](AGENTS.md) for conventions, packaging and release details, and [PLAN.md](PLAN.md) for what's next. Issues and pull requests are welcome.

## License

MIT — see [LICENSE](LICENSE).
