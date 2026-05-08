FIREWALL_URL="http://192.168.249.1:1000"

echo "Fetching available WiFi connections..."
echo "----------------------------------------"
nmcli -f NAME,UUID,DEVICE connection show
echo "----------------------------------------"

read -p "Choose the row of your wifi: " ROW

# Use -f with terse mode for reliable parsing
SELECTED=$(nmcli -t -f NAME,UUID,DEVICE connection show | sed -n "${ROW}p")

COLLEGE_SSID=$(echo "$SELECTED" | cut -d: -f1)
COLLEGE_UUID=$(echo "$SELECTED" | cut -d: -f2)
IFACE=$(echo "$SELECTED" | cut -d: -f3)

echo -e "\n--- Selected Network Details ---"
echo "SSID: $COLLEGE_SSID"
echo "UUID: $COLLEGE_UUID"
echo "Interface: $IFACE"
echo "--------------------------------"


echo "Creating configuration directory..."
mkdir -p ~/.config/wifi-automation/
echo "Creating configuration file..."
touch ~/.config/wifi-automation/wifi-login.conf
echo "Securing configuration file..."
chmod 600 ~/.config/wifi-automation/wifi-login.conf 

echo ""
read -p "Enter your username for wifi: " USERNAME
echo "USERNAME=$USERNAME" >> ~/.config/wifi-automation/wifi-login.conf
read -p "Enter your password for wifi: " PASSWORD
echo "PASSWORD=$PASSWORD" >> ~/.config/wifi-automation/wifi-login.conf


echo "Saving configuration details..."
echo "COLLEGE_SSID=$COLLEGE_SSID" >> ~/.config/wifi-automation/wifi-login.conf
echo "COLLEGE_UUID=$COLLEGE_UUID" >> ~/.config/wifi-automation/wifi-login.conf
echo "IFACE=$IFACE" >> ~/.config/wifi-automation/wifi-login.conf

ACTUAL_USER=$(whoami)

echo "ACTUAL_USER=$ACTUAL_USER" >> ~/.config/wifi-automation/wifi-login.conf

echo "FIREWALL_URL=$FIREWALL_URL" >> ~/.config/wifi-automation/wifi-login.conf

echo -e "\n[1/5] Setting execute permissions on scripts..."
chmod +x 90-wifi-login wifi-keepalive.sh wifi-login.sh

echo "[2/5] Copying files to system directories (this will require sudo/root access)..."
sudo cp 90-wifi-login /etc/NetworkManager/dispatcher.d/
sudo cp wifi-login.sh /usr/local/bin/
sudo cp wifi-keepalive.sh /usr/local/bin/
sudo cp wifi-keepalive.service /etc/systemd/system/
sudo cp wifi-keepalive.timer /etc/systemd/system/

echo "[3/5] Enabling and starting systemd timer/service..."
sudo systemctl daemon-reload
sudo systemctl enable wifi-keepalive.timer
sudo systemctl start wifi-keepalive.timer

echo "[4/5] Restarting NetworkManager to apply dispatcher script..."
sudo systemctl restart NetworkManager

echo "[5/5] Verifying installation status..."
IS_ACTIVE=$(systemctl is-active wifi-keepalive.timer)

if [ "$IS_ACTIVE" = "active" ]; then
    echo -e "\n✅ Setup completed successfully! WiFi Login Automation is active and running."
else
    echo -e "\n❌ Setup failed. The keepalive timer did not start successfully. :("
fi