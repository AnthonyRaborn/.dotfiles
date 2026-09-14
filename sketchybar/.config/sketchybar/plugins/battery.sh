#!/usr/bin/env bash
BATT_FULL=$(printf '\xef\x89\x80')
BATT_75=$(printf '\xef\x89\x81')
BATT_50=$(printf '\xef\x89\x82')
BATT_LOW=$(printf '\xef\x89\x83')
BATT_CHARGE=$(printf '\xef\x87\xa6')

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | head -1 | tr -d '%')
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

if [ "$PERCENTAGE" -gt 80 ]; then
  ICON=$BATT_FULL
elif [ "$PERCENTAGE" -gt 50 ]; then
  ICON=$BATT_75
elif [ "$PERCENTAGE" -gt 20 ]; then
  ICON=$BATT_LOW
else
  ICON=$BATT_LOW
fi

if [ -n "$CHARGING" ]; then
  ICON=$BATT_CHARGE
fi

sketchybar --set battery icon="$ICON" label="${PERCENTAGE}%"
