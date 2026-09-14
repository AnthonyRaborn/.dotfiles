#!/usr/bin/env bash
SPACE_ID=$1

# Hardcoded, since this script runs as its own process and
# does not inherit variables exported in sketchybarrc
CYAN=0xff95E6CB
ORANGE=0xffFF8F40

FOCUSED=$(yabai -m query --spaces --space "$SPACE_ID" | grep '"has-focus"' | grep -c true)

if [ "$FOCUSED" = "1" ]; then
  sketchybar --set space.$SPACE_ID icon.color=$ORANGE
else
  sketchybar --set space.$SPACE_ID icon.color=$CYAN
fi
