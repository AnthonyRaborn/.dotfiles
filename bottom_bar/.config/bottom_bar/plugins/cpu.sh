#!/usr/bin/env bash
CPU=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
bottom_bar --set cpu label="${CPU}%"
