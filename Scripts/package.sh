#!/usr/bin/env bash
# Builds a Release archive and packages Globalmoji.app into a DMG and zip under dist/.
# Signs with Developer ID and notarises when credentials are present, else ad-hoc.
#
# Usage: Scripts/package.sh [version]
# Env:   CODE_SIGN_IDENTITY  e.g. "Developer ID Application" (default "-" = ad-hoc)
#        DEVELOPMENT_TEAM    Apple team ID (required with Developer ID)
#        ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH   App Store Connect API key for notarytool
#        GIPHY_API_KEY       baked into Info.plist
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION="${1:-$(git describe --tags --always)}"
VERSION="${VERSION#v}"
DIST="dist"
ARCHIVE="build/Globalmoji.xcarchive"
APP="$ARCHIVE/Products/Applications/Globalmoji.app"
IDENTITY="${CODE_SIGN_IDENTITY:--}"
SIGNED=false
[[ "$IDENTITY" != "-" ]] && SIGNED=true

rm -rf "$DIST" "$ARCHIVE"
mkdir -p "$DIST"

xcodebuild -project Globalmoji.xcodeproj -scheme Globalmoji -configuration Release \
  -archivePath "$ARCHIVE" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}" \
  GIPHY_API_KEY="${GIPHY_API_KEY:-}" \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}" \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  archive | { command -v xcbeautify >/dev/null && xcbeautify || cat; }

notarize() {
  local path="$1"
  echo "Notarising $(basename "$path")…"
  xcrun notarytool submit "$path" \
    --key "$ASC_KEY_PATH" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID" \
    --wait --timeout 30m
}

CAN_NOTARIZE=false
if $SIGNED; then
  codesign --verify --deep --strict --verbose=2 "$APP"
  if [[ -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" && -f "${ASC_KEY_PATH:-}" ]]; then
    CAN_NOTARIZE=true
    ditto -c -k --keepParent "$APP" "build/notarize.zip"
    notarize "build/notarize.zip"
    xcrun stapler staple "$APP"
  else
    echo "Signed with Developer ID but no App Store Connect key present; skipping notarisation." >&2
  fi
fi

STAGING="build/dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
DMG="$DIST/Globalmoji-$VERSION.dmg"
hdiutil create -volname "Globalmoji" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
if $SIGNED; then
  codesign --sign "$IDENTITY" --timestamp "$DMG"
  if $CAN_NOTARIZE; then
    notarize "$DMG"
    xcrun stapler staple "$DMG"
  fi
fi

ditto -c -k --keepParent "$APP" "$DIST/Globalmoji-$VERSION.zip"
(cd "$DIST" && shasum -a 256 ./*.dmg ./*.zip > SHA256SUMS.txt)
if $CAN_NOTARIZE; then
  spctl --assess --type open --context context:primary-signature -v "$DMG"
  echo "notarized=true" >> "${GITHUB_OUTPUT:-/dev/null}"
else
  echo "notarized=false" >> "${GITHUB_OUTPUT:-/dev/null}"
fi
echo "Packaged version $VERSION (signed=$SIGNED notarized=$CAN_NOTARIZE):"
ls -la "$DIST"
