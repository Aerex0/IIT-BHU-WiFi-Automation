FIREWALL_URL="http://192.168.249.1:1000"

UUIDS=$(nmcli connection show)

echo "$UUIDS"

read -p "Choose the row of your wifi: " ROW

COLLEGE_SSID=$(echo "$UUIDS" | awk -v row="$ROW" 'NR==row+1 {print $1}')
COLLEGE_UUID=$(echo "$UUIDS" | awk -v row="$ROW" 'NR==row+1 {print $2}')
IFACE=$(echo "$UUIDS" | awk -v row="$ROW" 'NR==row+1 {print $4}')

echo "$COLLEGE_SSID"
echo "$COLLEGE_UUID"
echo "$IFACE"

mkdir -p ~/.config/wifi-automation/

read -p "Enter your username for wifi: " USERNAME
echo "USERNAME=$USERNAME" >> ~/.config/wifi-automation/wifi-login.conf
read -p "Enter your password for wifi: " PASSWORD
echo "PASSWORD=$PASSWORD" >> ~/.config/wifi-automation/wifi-login.conf

chmod 600 ~/.config/wifi-automation/wifi-login.conf


echo "COLLEGE_SSID=$COLLEGE_SSID" >> ~/.config/wifi-automation/wifi-login.conf
echo "COLLEGE_UUID=$COLLEGE_UUID" >> ~/.config/wifi-automation/wifi-login.conf
echo "IFACE=$IFACE" >> ~/.config/wifi-automation/wifi-login.conf

ACTUAL_USER=$(whoami)

echo "ACTUAL_USER=$ACTUAL_USER" >> ~/.config/wifi-automation/wifi-login.conf

echo "FIREWALL_URL=$FIREWALL_URL" >> ~/.config/wifi-automation/wifi-login.conf

chmod +x 90-wifi-login wifi-keepalive.sh wifi-login.sh
sudo cp 90-wifi-login /etc/NetworkManager/dispatcher.d/
sudo cp wifi-login.sh /usr/local/bin/
sudo cp wifi-keepalive.sh /usr/local/bin/
sudo cp wifi-keepalive.service /etc/systemd/system/
sudo cp wifi-keepalive.timer /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable wifi-keepalive.timer
sudo systemctl start wifi-keepalive.timer

sudo systemctl restart NetworkManager

IS_ACTIVE=$(systemctl is-active wifi-keepalive.timer)

if [ "$IS_ACTIVE" = "active" ]; then
    echo "setup completed, wifi-login-automation active and running"
else
    echo "setup failed..:("
fi