#!/usr/bin/env bash
MUTED=$(osascript -e 'output muted of (get volume settings)')
VOLUME=$(osascript -e 'output volume of (get volume settings)')

VOL_MUTE=$(printf '\xef\x80\xa6')
VOL_LOW=$(printf '\xef\x80\xa7')
VOL_HIGH=$(printf '\xef\x80\xa8')

if [ "$MUTED" = "true" ]; then
  $BAR_NAME --set volume icon="$VOL_MUTE" label=" Muted"
elif [ "$VOLUME" -lt 50 ]; then
  $BAR_NAME --set volume icon="$VOL_LOW" label=" ${VOLUME}%"
else
  $BAR_NAME --set volume icon="$VOL_HIGH" label=" ${VOLUME}%"
fi
