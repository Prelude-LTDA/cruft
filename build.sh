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

# Pick a signing identity. Order:
#   1. PRELUDE_SIGN_IDENTITY env var (explicit override)
#   2. First "Developer ID Application" identity in the keychain
#   3. Ad-hoc ("-")
# Developer ID gets Hardened Runtime + secure timestamp (required for
# eventual notarization, harmless without it). Ad-hoc gets neither —
# Hardened Runtime + ad-hoc + quarantine makes AMFI reject the binary
# at execve on the recipient's machine (kernel EACCES, surfaces as
# fish's "No permission").
SIGN_IDENTITY="${PRELUDE_SIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]]; then
    SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
        | awk -F'"' '/Developer ID Application/ {print $2; exit}')
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "→ signing as $SIGN_IDENTITY"
    codesign --force --sign "$SIGN_IDENTITY" \
        --entitlements "$ROOT/Resources/Cruft.entitlements" \
        --options runtime \
        --timestamp \
        "$APP_DIR"
else
    echo "→ ad-hoc signing (no Developer ID Application cert found)"
    codesign --force --sign - \
        --entitlements "$ROOT/Resources/Cruft.entitlements" \
        --timestamp=none \
        "$APP_DIR"
fi

echo "✓ $APP_DIR"
echo "  run: open $APP_DIR"

# Package for distribution as a DMG rather than zip. macOS's stock
# /usr/bin/zip doesn't store Unix mode bits, so a round-trip through
# Finder "Compress" / Archive Utility drops the +x off
# Contents/MacOS/<binary> and the recipient sees "Failed to execute
# process: No permission". tar preserves mode bits fine on its own,
# but Gmail/Drive/Slack will sometimes re-wrap a .tar.gz attachment as
# zip on download, reintroducing the same loss. DMG sidesteps both:
# POSIX modes, xattrs, and codesign blobs all survive end to end.
# Notarize the .app first (before packaging the DMG) so the
# notarization ticket can be stapled to the .app itself. Stapling is
# what lets Gatekeeper validate the notarization offline; without
# stapling, first-launch on a recipient's machine has to phone home to
# Apple.
#
# Gated on PRELUDE_NOTARIZE=1 because notarytool submission takes 1-5
# minutes and requires network + keychain credentials. Day-to-day
# builds skip it; release builds set the flag. Profile is shared across
# all Prelude apps (default name: prelude-notary). One-time setup:
#
#   xcrun notarytool store-credentials "prelude-notary" \
#       --key ~/.keys/AuthKey_<KEY_ID>.p8 \
#       --key-id <KEY_ID> \
#       --issuer <ISSUER_UUID>
NOTARY_PROFILE="${PRELUDE_NOTARY_PROFILE:-prelude-notary}"
if [[ "${PRELUDE_NOTARIZE:-0}" == "1" ]]; then
    echo "→ notarizing $APP_NAME.app (this can take a few minutes)"
    NOTARY_ZIP=$(mktemp -d)/"$APP_NAME.zip"
    # ditto preserves codesign blobs + xattrs; /usr/bin/zip mangles them.
    ditto -c -k --keepParent "$APP_DIR" "$NOTARY_ZIP"
    xcrun notarytool submit "$NOTARY_ZIP" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    rm -f "$NOTARY_ZIP"
    echo "→ stapling notarization ticket to .app"
    xcrun stapler staple "$APP_DIR"
fi

echo "→ packaging DMG"
DMG_PATH="$BUILD_DIR/Cruft.dmg"
rm -f "$DMG_PATH"

# Detach any stale "/Volumes/Cruft*" mounts left over from previous
# builds or `open Cruft.dmg` invocations. dmgbuild needs to mount the
# volume under exactly /Volumes/$APP_NAME during its layout phase; if
# the name is already taken, macOS auto-numbers (Cruft 1, Cruft 2…)
# and ditto inside dmgbuild fails with "Operation not permitted".
for _vol in /Volumes/"$APP_NAME"*; do
    [[ -d "$_vol" ]] && hdiutil detach "$_vol" -force >/dev/null 2>&1 || true
done

# dmgbuild (pip/pipx package) writes the .DS_Store directly via its
# ds_store library — no Finder, no AppleScript, no automation
# permission prompts, no sync timing race. Settings live in a small
# Python file at Resources/DMGSettings.py; the moving parts (.app path
# and optional background) come in via -D flags.
DMG_BG=""
if [[ -f "$ROOT/Resources/DMGBackground.png" ]]; then
    DMG_BG="$ROOT/Resources/DMGBackground.png"
fi

if ! command -v dmgbuild >/dev/null 2>&1; then
    echo "✗ dmgbuild not found on PATH. Install once with:"
    echo "    pipx install dmgbuild"
    exit 1
fi

dmgbuild \
    -s "$ROOT/Resources/DMGSettings.py" \
    -D app_path="$APP_DIR" \
    -D bg_image="$DMG_BG" \
    "$APP_NAME" \
    "$DMG_PATH" >/dev/null

# Sign the DMG itself with the same Developer ID identity. Without
# this, `spctl -a -t install` rejects the DMG with "no usable
# signature" — the .app inside is fine, but Gatekeeper's installer
# assessment of the container fails. Notarization will also refuse to
# accept an unsigned DMG.
if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "→ signing DMG"
    codesign --force --sign "$SIGN_IDENTITY" \
        --timestamp \
        "$DMG_PATH"
fi

# Notarize+staple the DMG. The .app inside is already stapled, so this
# layer only matters when the DMG is itself the unit Gatekeeper
# inspects (e.g. `spctl -a -t install`, or an offline first-mount on a
# fresh machine).
if [[ "${PRELUDE_NOTARIZE:-0}" == "1" ]]; then
    echo "→ notarizing DMG"
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    echo "→ stapling notarization ticket to DMG"
    xcrun stapler staple "$DMG_PATH"
fi

echo "    ✓ $DMG_PATH"
echo "  share: $DMG_PATH"
