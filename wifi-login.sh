#!/bin/bash

# Hardcode the actual user's home directory
ACTUAL_USER="yourusername"  # Replace with your username
ACTUAL_HOME="/home/${ACTUAL_USER}"
CONFIG_FILE="${ACTUAL_HOME}/.config/wifi-login.conf"

# For notifications to work when run as root
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
export XAUTHORITY="${ACTUAL_HOME}/.Xauthority"

# Credentials
USERNAME=""
PASSWORD=""

FIREWALL_URL="http://192.168.249.1:1000"

# Source config file
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ]; then
    echo "$(date) Error: USERNAME and PASSWORD must be set" >&2
    exit 1
fi

# Function to send notifications as the actual user
send_notification() {
    if [ -n "$ACTUAL_USER" ]; then
        sudo -u "$ACTUAL_USER" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "$@" 2>/dev/null || true
    fi
}

wifi_connect() {
    echo "$(date) Starting wifi_connect function"
    
    local probe_response
    probe_response=$(curl -k -L --silent --interface wlan0 --connect-timeout 10 --max-time 15 \
        "http://www.google.com/generate_204" 2>&1)
    
    echo "$(date) Probe response received"
    
    local login_form_url
    login_form_url=$(echo "${probe_response}" |
        grep -oE 'window\.location="[^"]*"' |
        sed -E 's/.*location="([^"]+)".*/\1/' 2>/dev/null)
    
    echo "$(date) Login form URL: ${login_form_url}"
    
    if [ -z "${login_form_url}" ]; then
        echo "$(date) Error: Could not extract login form URL"
        return 1
    fi

    local login_page_html
    login_page_html=$(curl -k -L --silent --interface wlan0 --connect-timeout 10 --max-time 15 \
        "${login_form_url}" 2>&1)
    
    echo "$(date) Login page HTML retrieved"

    local magic_token
    magic_token=$(echo "${login_page_html}" |
        grep -oE 'name="magic" value="[^"]+"' |
        head -1 |
        sed -E 's/.*value="([^"]+)".*/\1/' 2>/dev/null)
    
    echo "$(date) Magic token: ${magic_token}"
    
    if [ -z "${magic_token}" ]; then
        echo "$(date) Error: Could not extract magic token"
        return 1
    fi

    # Main login POST request
    echo "$(date) Sending login POST request"
    local login_response
    login_response=$(curl -k -L --silent --interface wlan0 --connect-timeout 10 --max-time 15 -X POST \
            -H "Origin: ${FIREWALL_URL}" \
            -H "Referer: ${login_form_url}" \
            --data-urlencode "4Tredir=http://8.8.8.8" \
            --data-urlencode "magic=${magic_token}" \
            --data-urlencode "username=${USERNAME}" \
            --data-urlencode "password=${PASSWORD}" \
            --data-urlencode "submit=Continue" \
            "${FIREWALL_URL}/" 2>&1)
    
    echo "$(date) Login response: ${login_response}"
}

CHECK_NET() {
    curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 http://clients3.google.com/generate_204 2>/dev/null
}

echo "$(date) Script started"

CHECK=$(CHECK_NET)
echo "$(date) Initial connectivity check: ${CHECK}"

if [ "$CHECK" != "204" ]; then
    echo "$(date) Not connected, attempting login"
    send_notification "WiFi Login" "Attempting to log in to IIT BHU WiFi network..."
    
    wifi_connect
    
    sleep 3
    CHECK=$(CHECK_NET)
    echo "$(date) Post-login connectivity check: ${CHECK}"
    
    if [ "$CHECK" = "204" ]; then
        echo "$(date) Login successful"
        send_notification "WiFi Login" "Successfully logged in to IIT BHU WiFi network."
    else
        echo "$(date) Login failed"
        send_notification "WiFi Login" "Failed to log in to IIT BHU WiFi network."
    fi
else
    echo "$(date) Already connected"
    send_notification "WiFi Login" "Already connected to the internet."
fi

echo "$(date) Script completed"