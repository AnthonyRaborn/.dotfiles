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

"$DESKTOPPR_BIN" "$image"
echo "wallpaper-clock: set $(basename "$image") for hour ${hour}"
