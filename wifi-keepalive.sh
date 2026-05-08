#!/bin/bash

# You may need to change this to your wifi interface
IFACE=""

# SSID of the college wifi
COLLEGE_SSID=""

# Find config file in home directories (since this runs as root)
CONFIG_FILE=$(ls /home/*/.config/wifi-automation/wifi-login.conf 2>/dev/null | head -n 1)

# Source config file
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    ACTUAL_HOME="/home/${ACTUAL_USER}"
fi

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