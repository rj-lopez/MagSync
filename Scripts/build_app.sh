#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="1.0"
DIST="dist"

echo "=== Building release binaries ==="
swift build -c release

BUILD_DIR=".build/release"
APP_BUNDLE="$DIST/MagSync.app"
CONTENTS="$APP_BUNDLE/Contents"

echo "=== Assembling .app bundle ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

cp "Resources/Info.plist"            "$CONTENTS/Info.plist"
printf "APPL????"                   > "$CONTENTS/PkgInfo"
cp "$BUILD_DIR/MagSafeLEDSync"       "$CONTENTS/MacOS/MagSafeLEDSync"
chmod 755                            "$CONTENTS/MacOS/MagSafeLEDSync"

echo "=== Code signing (ad-hoc) ==="
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Staging PKG payloads ==="

# App payload: MagSync.app → /Applications/
#              LaunchAgent  → /Library/LaunchAgents/
rm -rf "$DIST/pkg-root-app"
mkdir -p "$DIST/pkg-root-app/Applications"
mkdir -p "$DIST/pkg-root-app/Library/LaunchAgents"
cp -R "$APP_BUNDLE" "$DIST/pkg-root-app/Applications/"
cp "Resources/com.rjlopez.magsync.plist" \
   "$DIST/pkg-root-app/Library/LaunchAgents/com.rjlopez.magsync.plist"

# Helper payload: smc-write → /usr/local/bin/
# (postinstall script will set setuid root)
rm -rf "$DIST/pkg-root-helper"
mkdir -p "$DIST/pkg-root-helper/usr/local/bin"
cp "$BUILD_DIR/smc-write" "$DIST/pkg-root-helper/usr/local/bin/smc-write"
chmod 755 "$DIST/pkg-root-helper/usr/local/bin/smc-write"

echo "=== Building component packages ==="
pkgbuild \
  --root "$DIST/pkg-root-app" \
  --install-location / \
  --identifier com.rjlopez.magsync.app \
  --version "$VERSION" \
  "$DIST/MagSync-app.pkg"

pkgbuild \
  --root "$DIST/pkg-root-helper" \
  --install-location / \
  --identifier com.rjlopez.magsync.helper \
  --version "$VERSION" \
  --scripts "Scripts/pkg-scripts" \
  "$DIST/MagSync-helper.pkg"

echo "=== Building product archive ==="
productbuild \
  --distribution "Resources/Distribution.xml" \
  --package-path "$DIST" \
  "$DIST/MagSync-$VERSION.pkg"

echo "=== Creating DMG ==="
rm -f "$DIST/MagSync-$VERSION.dmg"
hdiutil create \
  -volname "MagSync $VERSION" \
  -srcfolder "$DIST/MagSync-$VERSION.pkg" \
  -ov \
  -format UDZO \
  "$DIST/MagSync-$VERSION.dmg"

echo ""
echo "Done."
echo "  PKG: $DIST/MagSync-$VERSION.pkg"
echo "  DMG: $DIST/MagSync-$VERSION.dmg"
