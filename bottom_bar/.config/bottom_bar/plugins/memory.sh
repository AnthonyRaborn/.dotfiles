#!/usr/bin/env bash
USED=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%')

if [ -z "$USED" ]; then
  $BAR_NAME --set memory label="N/A"
else
  FREE=$USED
  USED_PCT=$((100 - FREE))
  $BAR_NAME --set memory label="${USED_PCT}%"
fi
