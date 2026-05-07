#!/bin/bash

# You may need to change this to your wifi interface
IFACE="wlan0"

# SSID of the college wifi
COLLEGE_SSID="IIT(BHU)"

# Check if connected to IIT(BHU)
SSID=$(iw dev "${IFACE}" link 2>/dev/null | awk -F': ' '/SSID/ {print $2}')
[ "$SSID" != "${COLLEGE_SSID}" ] && exit 0

# Check internet connectivity
CHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://clients3.google.com/generate_204)

if [ "$CHECK" != "204" ]; then
    echo "$(date) Session expired, re-authenticating..." >> /tmp/wifi-keepalive.log
    /usr/local/bin/wifi-login.sh >> /tmp/wifi-login.log 2>&1
else
    echo "$(date) Session active, no action needed" >> /tmp/wifi-keepalive.log
fi