#!/usr/bin/env bash
WEATHER=$(curl -s "wttr.in/?format=%t+%C" --max-time 5)

if [ -z "$WEATHER" ]; then
  sketchybar --set weather label="N/A"
else
  sketchybar --set weather label="$WEATHER"
fi
