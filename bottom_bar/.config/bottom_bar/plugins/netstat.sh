#!/usr/bin/env bash
IFACE="en0"

RX1=$(netstat -ib | grep -m1 "$IFACE" | awk '{print $7}')
TX1=$(netstat -ib | grep -m1 "$IFACE" | awk '{print $10}')
sleep 1
RX2=$(netstat -ib | grep -m1 "$IFACE" | awk '{print $7}')
TX2=$(netstat -ib | grep -m1 "$IFACE" | awk '{print $10}')

RX_RATE=$(( (RX2 - RX1) / 1024 ))
TX_RATE=$(( (TX2 - TX1) / 1024 ))

$BAR_NAME --set netstat label="↓${RX_RATE}K ↑${TX_RATE}K"
