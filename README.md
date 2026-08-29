# Globalmoji

A native, open-source macOS emoji picker in the style of Slack/Discord (and [Rocket](https://matthewpalmer.net/rocket/)). Type `:` followed by a name in any app to search emoji, GIFs and ASCII emoticons and insert them inline.

**Status:** early development — see [PLAN.md](PLAN.md).

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26 (to build)

## Building

```sh
make generate   # regenerate Globalmoji.xcodeproj from project.yml (requires xcodegen)
make build
make test
```

Globalmoji needs the **Accessibility** and **Input Monitoring** permissions to observe the `:` trigger and insert text. It runs outside the App Sandbox and is not distributed via the Mac App Store.

## License

MIT — see [LICENSE](LICENSE).
