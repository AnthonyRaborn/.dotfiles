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

# macOS 14+ keeps every space's and display's wallpaper here. Editing this
# and restarting WallpaperAgent is the only way to change *all* spaces;
# desktoppr is only used as a fallback on older macOS without this store.
STORE="$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"

# Resolve desktoppr regardless of whether this runs under a login shell
# with Homebrew on PATH (launchd agents often don't inherit your shell PATH).
DESKTOPPR_BIN=""
for candidate in "$(command -v desktoppr || true)" /opt/homebrew/bin/desktoppr /usr/local/bin/desktoppr; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        DESKTOPPR_BIN="$candidate"
        break
    fi
done

if [[ ! -f "$STORE" && -z "$DESKTOPPR_BIN" ]]; then
    echo "wallpaper-clock: no wallpaper store at $STORE and desktoppr not found." >&2
    echo "wallpaper-clock: install desktoppr with 'brew install desktoppr'." >&2
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

if [[ -f "$STORE" ]]; then
    # Order matters. WallpaperAgent keeps the whole store in memory and
    # writes it back out on any wallpaper change, so an edit made while it
    # is running -- or made just before it restarts and re-reads -- gets
    # clobbered by its stale copy, leaving every space on the old image.
    # Rewrite the store first, then kill the agent so its next launch reads
    # the new file. (This is also why desktoppr isn't used here: poking it
    # after the edit triggers exactly that clobber.)
    changed="$(/usr/bin/python3 - "$STORE" "$image" <<'PY'
import plistlib, sys, pathlib

store, image = sys.argv[1], sys.argv[2]
url = pathlib.Path(image).resolve().as_uri()
with open(store, "rb") as f:
    data = plistlib.load(f)

changed = False

def retarget(node):
    """Point every image-file Desktop choice under `node` at `url`."""
    global changed
    if not isinstance(node, dict):
        return
    for choice in node.get("Desktop", {}).get("Content", {}).get("Choices", []):
        if choice.get("Provider") != "com.apple.wallpaper.choice.image":
            continue
        cfg = plistlib.loads(choice["Configuration"])
        if cfg.get("url", {}).get("relative") != url:
            cfg["url"] = {"relative": url}
            choice["Configuration"] = plistlib.dumps(cfg, fmt=plistlib.FMT_BINARY)
            changed = True

# Every node that can carry a Desktop choice. Missing SystemDefault and the
# top-level Displays was the other half of the bug: new spaces and the
# display fallback kept inheriting the stale image.
retarget(data.get("SystemDefault"))
retarget(data.get("AllSpacesAndDisplays"))
for display in data.get("Displays", {}).values():
    retarget(display)
for space in data.get("Spaces", {}).values():
    retarget(space.get("Default"))
    for display in space.get("Displays", {}).values():
        retarget(display)

if changed:
    with open(store, "wb") as f:
        plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)
print("1" if changed else "0")
PY
)"

    if [[ "$changed" == "1" ]]; then
        # Relaunches on demand and re-reads the store we just wrote.
        killall WallpaperAgent 2>/dev/null || true
        echo "wallpaper-clock: set $(basename "$image") for hour ${hour} (all spaces)"
    else
        echo "wallpaper-clock: already on $(basename "$image") for hour ${hour}"
    fi
elif [[ -n "$DESKTOPPR_BIN" ]]; then
    # Pre-Sonoma fallback: current space only.
    "$DESKTOPPR_BIN" "$image"
    echo "wallpaper-clock: set $(basename "$image") for hour ${hour}"
fi
