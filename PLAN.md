# Emoji Picker for macOS — Implementation Plan

Open-source (MIT), native macOS, Rocket-Pro-style `:` emoji picker.

## 1. Product scope

### v1 (parity with Rocket Pro core)
- Global `:` trigger in any text field. Typing `:smi` opens a floating popover near the caret with live-filtered results; `Enter`/`Tab` inserts, `Esc` dismisses, arrows navigate, `1–9` quick-pick.
- Tabs / modes inside the popover: **Emoji**, **GIF**, **ASCII** (switch with `Tab`/`Shift-Tab` or prefix e.g. `:gif ` / `:ascii `).
- Emoji search over Unicode name, CLDR annotations/keywords, and Slack/GitHub shortcodes. Skin-tone modifier (global default + per-emoji override via `Shift-Enter` or long-press).
- GIF search (Giphy) with animated previews; insert as image on pasteboard (falls back to URL for apps that don't accept image paste).
- ASCII/kaomoji search (`shrug` → `¯\_(ツ)_/¯`).
- Recents (per mode).
- Preferences (SwiftUI Settings window):
  - Trigger key (default `:`), minimum characters before popup (default 2).
  - Enable/disable per app (allow-list or deny-list; picker of running/installed apps, plus bundle-ID entry).
  - Skin tone default, popover appearance (light/dark/system, compact/large grid), launch at login.
  - Insert behaviour: emoji vs shortcode text, close-on-insert.
  - Giphy API key field (see open question).
- Menu bar item (no Dock icon) with quick access to picker, preferences, and pause toggle.
- Onboarding: Accessibility + Input Monitoring permission prompts with instructions.

### v2 (explicitly future)
- Favourites for emoji, GIFs and ASCII (pinned section at top of each mode).
- Searchable image store: drag/drop or paste images/stickers into a library, tag them, insert via `:`.
- Custom shortcodes/aliases; custom ASCII entries.
- Sparkle auto-update.

## 2. Architecture

```
Globalmoji.xcodeproj            # generated from project.yml (XcodeGen); both committed
├─ App/                         # AppKit lifecycle, menu bar, windows, permissions
│  ├─ GlobalmojiApp.swift       # NSApplication delegate, LSUIElement
│  ├─ MenuBar/
│  ├─ Picker/                   # NSPanel (non-activating) hosting SwiftUI picker view
│  ├─ Settings/                 # SwiftUI Settings scenes
│  └─ Onboarding/
├─ Packages/
│  ├─ PickerCore/               # pure Swift, testable, no AppKit UI
│  │  ├─ Emoji/                 # dataset loader, search index, skin-tone logic
│  │  ├─ ASCII/                 # kaomoji dataset + search
│  │  ├─ GIF/                   # GIFProvider protocol + GiphyProvider
│  │  ├─ Search/                # ranking: prefix > shortcode > keyword, recency boost
│  │  ├─ Storage/               # recents, favourites, settings (Codable JSON in App Support)
│  │  └─ AppRules/              # per-app enable/disable evaluation
│  └─ InputEngine/              # CGEvent tap, trigger state machine, text insertion
└─ Resources/                   # emoji.json, ascii.json, generated at build via script
```

- **Language/UI**: Swift 6 (strict concurrency), SwiftUI views inside an AppKit `NSPanel` (`.nonactivatingPanel`, floating level, `canBecomeKey = true` so we receive keys without stealing focus from the target app's window).
- **Deployment target**: macOS 26 (Tahoe).
- **Key capture**: `CGEvent.tapCreate` at session level (`.cgSessionEventTap`, `.headInsertEventTap`) listening to `keyDown`. Requires **Input Monitoring**; text insertion/backspacing requires **Accessibility**. Both prompted in onboarding, both checked on launch.
- **Trigger state machine** (in `InputEngine`):
  1. Idle → `:` typed at a word boundary → *Armed* (buffer empty).
  2. Armed + alphanumerics/`_-+` → buffer; once `buffer.count >= minChars` show panel.
  3. Space/punctuation/`Esc`/app switch/click elsewhere → reset.
  4. `Enter`/`Tab`/click result → insert: synthesise `⌫` × (buffer.count + 1) to remove typed `:query`, then insert.
  5. While the panel is visible, key events are swallowed by the tap and routed to the panel (arrows/enter/esc/typing).
- **Text insertion**: pasteboard-based — save existing pasteboard contents, write string/image, post `⌘V`, restore pasteboard after a short delay. Fallback for plain text: `CGEvent` with `keyboardSetUnicodeString` (works without touching the clipboard, but fails for GIFs and some Electron apps). Setting to choose strategy.
- **Per-app rules**: `NSWorkspace.shared.frontmostApplication?.bundleIdentifier` checked when arming. Rules stored as `[bundleID: enabled]` + a global mode (allow-list vs deny-list). Default deny-list includes terminals and password managers (`com.apple.Terminal`, `com.googlecode.iterm2`, `com.1password.*`), user-editable.
- **Caret positioning**: use `AXUIElement` `kAXSelectedTextRangeAttribute` + `kAXBoundsForRangeParameterizedAttribute` on the focused element to place the panel under the caret; fall back to the mouse location, then screen centre.
- **Data**:
  - Emoji: generate `emoji.json` from [emojibase](https://github.com/milesj/emojibase) (MIT) — includes Unicode names, CLDR keywords, shortcodes (Slack/GitHub/emojibase sets), skin-tone variants, group/subgroup ordering. A `Scripts/generate-emoji-data.swift` (or small Node script) regenerates the file; the generated JSON is committed.
  - ASCII/kaomoji: curated `ascii.json` (`name`, `text`, `keywords`), seeded from public-domain lists; contributors can add entries via PR.
  - GIF: `GIFProvider` protocol (`search(query:offset:)`, `trending()`), `GiphyProvider` first; provider abstraction leaves room for Tenor/Klipy.
- **Search**: in-memory index built at launch (~4k emoji + ~1k ASCII is trivial). Ranking: exact shortcode > shortcode prefix > name prefix > keyword match, tie-broken by recency/frequency. No dependency needed; if fuzzy is wanted later, add a small n-gram scorer in `PickerCore`.
- **Persistence**: Codable JSON files in `~/Library/Application Support/<AppName>/` (settings, recents, favourites). `UserDefaults` only for trivial flags. No SwiftData/Core Data — keeps the schema greppable for an OSS project. Image store (v2) = folder of files + `index.json`.
- **Networking**: `URLSession` + `async/await`. GIF thumbnails cached with `URLCache` + an in-memory `NSCache`; previews rendered with `CGImageSource` animation (or `NSImageView.animates`).
- **Dependencies**: none in v1 core. Candidates when needed: `LaunchAtLogin` (or `SMAppService` directly — prefer that, no dep), `Sparkle` (v2), `KeyboardShortcuts` by sindresorhus for the manual-open hotkey (MIT).
- **Sandbox**: off. Event taps and AX are incompatible with the App Sandbox, so distribution is outside the Mac App Store (Developer ID + notarisation). Hardened Runtime on.

## 3. Repo / tooling
- `Globalmoji.xcodeproj` generated by XcodeGen from `project.yml` (both committed); core logic in local SwiftPM packages so `swift test` works without Xcode UI.
- `swiftformat` + `swiftlint` configs; `Makefile` with `build`, `test`, `lint`, `archive`, `notarize`.
- GitHub Actions `checks.yml`: build + `swift test` on `macos-15`; `release.yml` on tag: archive, sign, notarise, staple, upload DMG/zip to GitHub Release, bump Homebrew cask (`bevanjkay/tap` or homebrew-cask once eligible).
- `LICENSE` (MIT), `README.md`, `CONTRIBUTING.md`, `AGENTS.md` (build/test commands, permission-testing notes).

## 4. Milestones

| # | Milestone | Deliverable |
|---|-----------|-------------|
| 0 | Scaffold | Xcode project, packages, menu bar app that launches, CI green, LICENSE/README |
| 1 | Emoji data + search | `PickerCore` emoji index, unit tests for ranking/shortcodes/skin tones |
| 2 | Input engine | Event tap, trigger state machine, insertion; onboarding for permissions; unit tests for state machine |
| 3 | Picker UI | Floating panel, grid, keyboard nav, caret positioning, recents, skin tone |
| 4 | Preferences | Settings window incl. per-app rules, trigger key, appearance, launch at login |
| 5 | ASCII mode | Dataset + tab in picker |
| 6 | GIF mode | Giphy provider, previews, image/URL insertion, API key handling |
| 7 | Release | Signing/notarisation workflow, DMG, Homebrew cask, v1.0 |
| 8 | v2 | Favourites → image store → Sparkle |

Each milestone is a PR (or a few) into `main`; nothing merged without approval.

## 5. Known risks
- **Electron/web apps** (Slack, Discord, Chrome): AX caret bounds are often missing → fallback positioning; `⌘V` works reliably, unicode-string injection sometimes doesn't. GIF insertion behaviour differs per app (Slack pastes file, Discord pastes attachment, browsers paste nothing) — needs a per-app test matrix.
- **Secure input** (password fields, Terminal with secure keyboard entry): event tap receives nothing — detect via `IsSecureEventInputEnabled()` and show a menu-bar hint rather than failing silently.
- **Permissions UX**: TCC resets when the bundle signature changes; dev builds must be signed with a stable identity or users re-grant constantly. Document in `AGENTS.md`.
- **Giphy key**: cannot be kept secret in an OSS binary — see question 2.

## 6. Decisions (2026-08-29)

1. Name **Globalmoji**, bundle ID `me.bevankay.globalmoji`.
2. GIFs via Giphy public API. Key is a non-secret build setting (`GIPHY_API_KEY`, injected in CI for releases) with a user-override field in Preferences; `GIFProvider` abstraction retained.
3. Minimum macOS 26 (Tahoe).
4. Per-app rules: enabled everywhere by default with a small default deny-list.
5. Emoji data from emojibase, generated JSON committed.
6. No Developer ID yet — release signing/notarisation deferred; CI builds unsigned/ad-hoc until then.
7. Extra Rocket Pro features (custom aliases, URL skipping, manual hotkey) deferred past v1.
