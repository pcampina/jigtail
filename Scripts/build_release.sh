#!/usr/bin/env bash
# Builds, signs, notarizes, and packages a distributable JigTail.dmg.
#
# One-time setup before this script can run:
#   1. A "Developer ID Application" signing certificate installed in your keychain
#      (Xcode > Settings > Accounts > Manage Certificates, or from developer.apple.com).
#   2. A notarytool keychain profile, created once with:
#        xcrun notarytool store-credentials "jigtail-notary" \
#          --apple-id "you@example.com" \
#          --team-id "YOURTEAMID" \
#          --password "an app-specific password from appleid.apple.com"
#      This stores credentials in the keychain under the profile name below —
#      nothing is hardcoded in this script or committed to the repo.
#
# Usage: Scripts/build_release.sh [version]
#   version defaults to the MARKETING_VERSION already set in project.yml.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SCHEME="JigTail"
CONFIGURATION="Release"
NOTARY_PROFILE="jigtail-notary"
BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/JigTail.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS_PLIST="$ROOT_DIR/Scripts/ExportOptions.plist"

VERSION="${1:-$(grep 'MARKETING_VERSION' project.yml | head -1 | awk '{print $2}' | tr -d '"')}"
DMG_PATH="$BUILD_DIR/JigTail-$VERSION.dmg"

echo "==> Regenerating Xcode project"
xcodegen generate

echo "==> Archiving ($CONFIGURATION)"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
xcodebuild -project JigTail.xcodeproj -scheme "$SCHEME" -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" archive

echo "==> Exporting signed .app"
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

APP_PATH="$EXPORT_PATH/JigTail.app"

echo "==> Zipping for notarization"
ZIP_PATH="$BUILD_DIR/JigTail.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "==> Submitting to Apple notary service (this can take a few minutes)"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Stapling notarization ticket"
xcrun stapler staple "$APP_PATH"

echo "==> Building DMG"
hdiutil create -volname "JigTail" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

echo "==> Done: $DMG_PATH"
shasum -a 256 "$DMG_PATH"
