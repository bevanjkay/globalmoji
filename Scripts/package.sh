#!/usr/bin/env bash
# Builds a Release archive and packages Globalmoji.app into a DMG and zip under dist/.
# Usage: Scripts/package.sh [version]
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${1:-$(git describe --tags --always)}"
VERSION="${VERSION#v}"
DIST="dist"
ARCHIVE="build/Globalmoji.xcarchive"
APP="$ARCHIVE/Products/Applications/Globalmoji.app"

rm -rf "$DIST" "$ARCHIVE"
mkdir -p "$DIST"

xcodebuild -project Globalmoji.xcodeproj -scheme Globalmoji -configuration Release \
  -archivePath "$ARCHIVE" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}" \
  GIPHY_API_KEY="${GIPHY_API_KEY:-}" \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" \
  archive | { command -v xcbeautify >/dev/null && xcbeautify || cat; }

if [[ -n "${CODE_SIGN_IDENTITY:-}" && "${CODE_SIGN_IDENTITY}" != "-" ]]; then
  codesign --verify --deep --strict "$APP"
fi

STAGING="build/dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Globalmoji" -srcfolder "$STAGING" -ov -format UDZO "$DIST/Globalmoji-$VERSION.dmg" >/dev/null

ditto -c -k --keepParent "$APP" "$DIST/Globalmoji-$VERSION.zip"
(cd "$DIST" && shasum -a 256 ./*.dmg ./*.zip > SHA256SUMS.txt)
echo "Packaged version $VERSION:"
ls -la "$DIST"
