k#!/usr/bin/env bash
GREEN=0xffAAD94C
IDLE_COLOR=0xff5c6773

INFO=$(media-control get 2>/dev/null)

if [ -z "$INFO" ] || [ "$INFO" = "null" ]; then
  $BAR_NAME --set media icon.drawing=on icon.color=$IDLE_COLOR label="No media playing"
  exit 0
fi

TITLE=$(echo "$INFO" | jq -r '.title // empty')
ARTIST=$(echo "$INFO" | jq -r '.artist // empty')

if [ -z "$TITLE" ]; then
  $BAR_NAME --set media icon.drawing=on icon.color=$IDLE_COLOR label="No media playing"
else
  $BAR_NAME --set media icon.drawing=on icon.color=$GREEN label="$ARTIST - $TITLE"
fi
