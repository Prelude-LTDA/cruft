#!/usr/bin/env bash
# Build and assemble Cruft.app.
# Usage: ./build.sh [debug|release]   (default: release)

set -euo pipefail

CONFIG="${1:-release}"
APP_NAME="Cruft"
BUNDLE_ID="ltda.prelude.Cruft"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "→ swift build -c $CONFIG"
swift build -c "$CONFIG" \
    -Xswiftc -target -Xswiftc arm64-apple-macosx26.0

BIN="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
[[ -x "$BIN" ]] || { echo "✗ binary not found at $BIN"; exit 1; }

echo "→ assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

# Copy brand logos — most SVGs from gilbarbara/logos (MIT, see
# Resources/Logos/CREDITS.md), plus a couple pulled from official sources
# (pnpm.svg, lmstudio.webp).
if [[ -d "$ROOT/Resources/Logos" ]]; then
    mkdir -p "$APP_DIR/Contents/Resources/Logos"
    for ext in svg webp png; do
        cp "$ROOT/Resources/Logos/"*.$ext "$APP_DIR/Contents/Resources/Logos/" 2>/dev/null || true
    done
fi

# App icon — macOS 26 pipeline:
#   1. actool compiles the .icon bundle into Assets.car (Liquid Glass data)
#      and a legacy AppIcon.icns (pre-26 fallback), both written into
#      Contents/Resources/.
#   2. Info.plist carries CFBundleIconFile (legacy .icns lookup) and
#      CFBundleIconName (new Assets.car lookup) — both set to "AppIcon".
# The `--app-icon`, the bundle stem, and CFBundleIconName must all match.
ICON_SRC="$ROOT/Icon/Icon.icon"
if [[ -d "$ICON_SRC" ]]; then
    echo "→ compiling app icon via actool"
    # Copy to a stem-matched name so actool accepts it.
    ICON_STAGING=$(mktemp -d)
    cp -R "$ICON_SRC" "$ICON_STAGING/AppIcon.icon"
    PARTIAL_PLIST="$ICON_STAGING/partial.plist"
    xcrun actool "$ICON_STAGING/AppIcon.icon" \
        --compile "$APP_DIR/Contents/Resources" \
        --output-partial-info-plist "$PARTIAL_PLIST" \
        --app-icon AppIcon \
        --include-all-app-icons \
        --target-device mac \
        --minimum-deployment-target 10.14 \
        --platform macosx \
        --output-format human-readable-text \
        --notices --warnings --errors 2>&1 | tail -3
    rm -rf "$ICON_STAGING"
    # Sanity check
    if [[ -f "$APP_DIR/Contents/Resources/Assets.car" ]]; then
        echo "    ✓ Assets.car"
    else
        echo "    ✗ Assets.car missing"
    fi
    if [[ -f "$APP_DIR/Contents/Resources/AppIcon.icns" ]]; then
        echo "    ✓ AppIcon.icns"
    else
        echo "    ✗ AppIcon.icns missing"
    fi
fi

# Write PkgInfo
printf "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo "→ ad-hoc signing"
codesign --force --sign - \
    --entitlements "$ROOT/Resources/Cruft.entitlements" \
    --options runtime \
    --timestamp=none \
    "$APP_DIR"

echo "✓ $APP_DIR"
echo "  run: open $APP_DIR"
