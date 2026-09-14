#!/usr/bin/env bash
AVAILABLE=$(df -H / | tail -1 | awk '{print $4}')
$BAR_NAME --set disk label="${AVAILABLE} free"
