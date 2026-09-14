k#!/usr/bin/env bash
CYAN=0xff95E6CB
RED=0xffF28779

# Check if Wi-Fi has an active IP address (works around the SSID restriction)
IP=$(ipconfig getifaddr en0 2>/dev/null)

if [ -z "$IP" ]; then
  bottom_bar --set network icon.color=$RED label="Offline"
else
  bottom_bar --set network icon.color=$CYAN label="Connected"
fi
