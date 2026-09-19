#!/usr/bin/env bash
#
# wallpaper-clock.sh
#
# Sets the macOS desktop picture to match the current local hour, picking
# from a directory of pre-rendered hourly wallpapers named like:
#   0000_night.png, 0100_night.png, ..., 2300_evening.png
#
# Requires: desktoppr (brew install desktoppr)
#
# Intended to be run hourly via a launchd agent (see
# com.raborn.wallpaper-clock.plist alongside this script), but is safe to
# run manually at any time to sync the wallpaper to the current hour.

set -euo pipefail

# Directory containing the hourly wallpaper PNGs. Adjust if you move them.
WALLPAPER_DIR="${WALLPAPER_CLOCK_DIR:-$HOME/.dotfiles/wallpapers/pixel-city}"

# Resolve desktoppr regardless of whether this runs under a login shell
# with Homebrew on PATH (launchd agents often don't inherit your shell PATH).
if command -v desktoppr >/dev/null 2>&1; then
    DESKTOPPR_BIN="$(command -v desktoppr)"
elif [[ -x /opt/homebrew/bin/desktoppr ]]; then
    DESKTOPPR_BIN=/opt/homebrew/bin/desktoppr
elif [[ -x /usr/local/bin/desktoppr ]]; then
    DESKTOPPR_BIN=/usr/local/bin/desktoppr
else
    echo "wallpaper-clock: desktoppr not found. Install with 'brew install desktoppr'." >&2
    exit 1
fi

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "wallpaper-clock: wallpaper directory not found: $WALLPAPER_DIR" >&2
    exit 1
fi

hour="$(date +%H)"

# Match this hour's file, e.g. hour=12 -> 1200_*.png
image="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f -iname "${hour}00_*.png" -print -quit)"

if [[ -z "$image" ]]; then
    echo "wallpaper-clock: no wallpaper found for hour ${hour} in ${WALLPAPER_DIR}" >&2
    exit 1
fi

# desktoppr only sets the wallpaper for the space currently on screen. Set
# that first, then rewrite the per-space entries in the wallpaper store so
# every other space/display follows (WallpaperAgent is restarted to reload).
"$DESKTOPPR_BIN" "$image"

STORE="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
if [[ -f "$STORE" ]]; then
    # Stop the agent first: it flushes its in-memory state on exit and would
    # clobber our edit. launchd restarts it and it re-reads the store.
    killall WallpaperAgent 2>/dev/null || true
    sleep 1
    changed="$(/usr/bin/python3 - "$STORE" "$image" <<'PY'
import plistlib, sys, pathlib

store, image = sys.argv[1], sys.argv[2]
url = pathlib.Path(image).resolve().as_uri()
with open(store, "rb") as f:
    data = plistlib.load(f)

def retarget(node):
    """Point an image-file Desktop entry at `url`; return True if changed."""
    changed = False
    content = node.get("Desktop", {}).get("Content", {})
    for choice in content.get("Choices", []):
        if choice.get("Provider") != "com.apple.wallpaper.choice.image":
            continue
        cfg = plistlib.loads(choice["Configuration"])
        if cfg.get("url", {}).get("relative") != url:
            cfg["url"] = {"relative": url}
            choice["Configuration"] = plistlib.dumps(cfg, fmt=plistlib.FMT_BINARY)
            changed = True
    return changed

changed = False
for space in data.get("Spaces", {}).values():
    changed |= retarget(space.get("Default", {}))
    for display in space.get("Displays", {}).values():
        changed |= retarget(display)

if changed:
    with open(store, "wb") as f:
        plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)
print("1" if changed else "0")
PY
)"
fi

echo "wallpaper-clock: set $(basename "$image") for hour ${hour}"
