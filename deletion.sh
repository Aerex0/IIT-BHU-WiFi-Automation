#!/bin/bash

CONF_FILE="$HOME/.config/wifi-automation/wifi-login.conf"

echo "WiFi Login Automation - Uninstaller"
echo "===================================="

echo -e "\n[1/5] Stopping and disabling systemd timer/service..."
sudo systemctl stop wifi-keepalive.timer
sudo systemctl disable wifi-keepalive.timer

echo "[2/5] Removing installed system files..."
sudo rm -f /etc/NetworkManager/dispatcher.d/90-wifi-login
sudo rm -f /usr/local/bin/wifi-login.sh
sudo rm -f /usr/local/bin/wifi-keepalive.sh
sudo rm -f /etc/systemd/system/wifi-keepalive.service
sudo rm -f /etc/systemd/system/wifi-keepalive.timer

echo "[3/5] Reloading systemd and restarting NetworkManager..."
sudo systemctl daemon-reload
sudo systemctl restart NetworkManager

echo "[4/5] Cleaning up logs..."
rm -f /tmp/wifi-*.log /tmp/nm-dispatcher.log

echo "[5/5] Handling credentials and config..."
if [ -f "$CONF_FILE" ]; then
    read -p "Remove saved credentials and config? (y/N): " REMOVE_CONF
    if [[ "$REMOVE_CONF" =~ ^[Yy]$ ]]; then
        rm -rf ~/.config/wifi-automation/
        echo "Config and credentials removed."
    else
        echo "Config kept at $CONF_FILE"
    fi
fi

IS_ACTIVE=$(systemctl is-active wifi-keepalive.timer 2>/dev/null)

if [ "$IS_ACTIVE" != "active" ]; then
    echo -e "\n✅ Uninstallation completed successfully!"
else
    echo -e "\n❌ Uninstallation may have failed. Timer is still active."
fi