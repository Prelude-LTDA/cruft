#!/usr/bin/env bash
# Wipe local Cruft state to simulate a fresh-user first-launch.
#
# By default this preserves TCC (Privacy & Security) grants. TCC tracks
# permission grants by code-signature identity, so they survive a
# normal reinstall — usually what you want. Pass --tcc to also reset
# those, which is useful when specifically retesting the FDA /
# Automation / Accessibility prompt flow.
#
# Usage: ./reset.sh [--tcc]
#        ./reset.sh --help

set -euo pipefail

BUNDLE_ID="ltda.prelude.Cruft"
DISPLAY_NAME="Cruft"

RESET_TCC=0
for arg in "$@"; do
    case "$arg" in
        --tcc) RESET_TCC=1 ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [--tcc]

Wipes local Cruft state (defaults, Application Support, caches, saved
window state, logs) to simulate a fresh-user first-launch.

  --tcc        Also reset TCC privacy permissions for the bundle.
               Useful when retesting the FDA / Automation prompt flow.
               Without this, TCC grants survive (tracked by signing
               identity).
  -h, --help   Show this help.
EOF
            exit 0
            ;;
        *)
            echo "✗ unknown argument: $arg" >&2
            echo "    run with --help for usage" >&2
            exit 1
            ;;
    esac
done

# Quit any running instance first — defaults / Saved State are not
# safe to wipe while the process is alive (cfprefsd caches in memory
# and re-flushes on quit, AppKit re-writes Saved State on quit).
if pgrep -x "$DISPLAY_NAME" >/dev/null 2>&1; then
    osascript -e "quit app \"$DISPLAY_NAME\"" >/dev/null 2>&1 || true
    # Give AppKit ~1s to finish writing state, then SIGKILL if it's
    # still around (scan in progress, modal sheet, etc.).
    for _ in 1 2 3; do
        sleep 1
        pgrep -x "$DISPLAY_NAME" >/dev/null 2>&1 || break
    done
    pkill -9 -x "$DISPLAY_NAME" 2>/dev/null || true
    echo "→ quit $DISPLAY_NAME"
else
    echo "→ $DISPLAY_NAME not running"
fi

# Helper: remove a path and report only if it actually existed.
remove() {
    local label="$1" path="$2"
    if [[ -e "$path" ]]; then
        rm -rf "$path"
        echo "    ✓ $label"
    fi
}

echo "→ wiping local state for $BUNDLE_ID"

# UserDefaults — also covers iCloud-synced prefs if any (none for
# Cruft today, but harmless if added later).
if defaults read "$BUNDLE_ID" >/dev/null 2>&1; then
    defaults delete "$BUNDLE_ID"
    echo "    ✓ defaults"
fi

# History store, on-disk scan caches, window/inspector state, logs.
remove "Application Support"     "$HOME/Library/Application Support/$DISPLAY_NAME"
remove "Caches"                  "$HOME/Library/Caches/$BUNDLE_ID"
remove "Saved Application State" "$HOME/Library/Saved Application State/$BUNDLE_ID.savedState"
remove "Logs"                    "$HOME/Library/Logs/$DISPLAY_NAME"

# Web-storage & cookie buckets — Cruft doesn't touch these today, but
# clean them up if they ever get created so the script stays a single
# source of truth.
remove "HTTPStorages"            "$HOME/Library/HTTPStorages/$BUNDLE_ID"
remove "Cookies"                 "$HOME/Library/Cookies/$BUNDLE_ID.binarycookies"

# WebKit per-bundle data, if any embedded WKWebView ever shows up.
remove "WebKit data"             "$HOME/Library/WebKit/$BUNDLE_ID"
remove "WebKit caches"           "$HOME/Library/Caches/$BUNDLE_ID/WebKit"

if [[ $RESET_TCC -eq 1 ]]; then
    echo "→ resetting TCC permissions"
    # `tccutil reset All <bundle>` clears every category (FDA,
    # Automation, Accessibility, etc.) that's been granted to the
    # bundle. macOS will re-prompt on next launch.
    tccutil reset All "$BUNDLE_ID" 2>&1 | sed 's/^/    /' || true
fi

echo "✓ done — next launch behaves like a fresh install"
