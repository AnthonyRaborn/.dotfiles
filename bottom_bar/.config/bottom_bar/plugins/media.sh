#!/usr/bin/env bash
INFO=$(media-control get 2>/dev/null)

if [ -z "$INFO" ] || [ "$INFO" = "null" ]; then
  $BAR_NAME --set media label="" icon.drawing=off
  exit 0
fi

TITLE=$(echo "$INFO" | jq -r '.title // empty')
ARTIST=$(echo "$INFO" | jq -r '.artist // empty')

if [ -z "$TITLE" ]; then
  $BAR_NAME --set media label="" icon.drawing=off
else
  $BAR_NAME --set media icon.drawing=on label="$ARTIST - $TITLE"
fi
