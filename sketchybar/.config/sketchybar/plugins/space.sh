#!/usr/bin/env bash
SPACE_ID=$1

CYAN=0xff95E6CB
ORANGE=0xffFF8F40
INACTIVE_BG=0x30ffffff
ACTIVE_BG=0xffFF8F40

FOCUSED=$(yabai -m query --spaces --space "$SPACE_ID" | grep '"has-focus"' | grep -c true)

if [ "$FOCUSED" = "1" ]; then
  sketchybar --set space.$SPACE_ID icon.color=0xff0A0E14 background.color=$ACTIVE_BG
else
  sketchybar --set space.$SPACE_ID icon.color=$CYAN background.color=$INACTIVE_BG
fi
