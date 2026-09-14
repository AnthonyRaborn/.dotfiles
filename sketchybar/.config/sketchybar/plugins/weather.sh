#!/usr/bin/env bash
mkdir -p ~/.cache
shortcuts run "GetWeatherText" --output-path ~/.cache/weather.txt 2>/dev/null
WEATHER=$(cat ~/.cache/weather.txt 2>/dev/null)

if [ -z "$WEATHER" ]; then
  sketchybar --set weather label="N/A"
else
  sketchybar --set weather label="$WEATHER"
fi
