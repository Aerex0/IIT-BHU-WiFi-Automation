# WiFi Login Automation

Automatic login system for captive portal WiFi networks (specifically designed for IIT(BHU) WiFi). This system automatically logs you in when you connect to the network and keeps your session alive by re-authenticating when it expires.

## Features

- ✅ **Automatic login** when connecting to WiFi
- ✅ **Session keepalive** - automatically re-authenticates when session expires
- ✅ **Desktop notifications** for login status
- ✅ **Detailed logging** for troubleshooting
- ✅ **Systemd integration** for reliability

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Customization](#customization)

## Prerequisites

Before installing, ensure you have:

- Linux system with NetworkManager (Yeah, Sorry Windows Guys :(  )
- systemd (most modern Linux distributions)
- `curl` installed
- `iw` and `nmcli` commands available
- Root/sudo access

**Check if you have the required tools:**
```bash
which curl iw nmcli systemctl
```

If any are missing, install them:
```bash
# Debian/Ubuntu
sudo apt install curl iw network-manager systemd

# Fedora/RHEL
sudo dnf install curl iw NetworkManager systemd

# Arch Linux
sudo pacman -S curl iw networkmanager systemd
```

## Installation

### Step 1: Clone or Download This Repository

```bash
cd ~/Documents
git clone https://github.com/Aerex0/IIT-BHU-WiFi-Automation
cd IIT-BHU-WiFi-Automation
```


### Step 2: Find Your WiFi Network UUID

You need the UUID of your WiFi connection:

```bash
nmcli connection show
```

Look for your WiFi network name and copy its UUID. Example output:
```
NAME         UUID                                  TYPE      DEVICE
IIT(BHU)     84aab8b1-7bda-4e94-bd52-06181ff6678f  wifi      wlan0
```

Copy the UUID (the long string with dashes).

### Step 3: Configure Credentials

For Security reasons prefer to create a configuration file for your credentials:

```bash
mkdir -p ~/.config
nano ~/.config/wifi-login.conf
```

Add your credentials:
```bash
USERNAME="your_username"
PASSWORD="your_password"
```

**Secure the file:**
```bash
chmod 600 ~/.config/wifi-login.conf
```

Or you can also choose to write the credentials directly in the `wifi-login.sh` file

### Step 4: Update Configuration Files

#### a) Edit `90-wifi-login`

Open the file:
```bash
nano 90-wifi-login
```

Update these values:
1. **Line 8:** Change `wlan0` to your interface if different (check with "ip link")
2. **Line 10:** Change `IIT(BHU)` to your WiFi SSID if different
3. **Line 12:** Change `84aab8b1-7bda-4e94-bd52-06181ff6678f` to your WiFi SSID if different

```bash
# Change it to your interface
IFACE="wlan0"
# Change it to the SSID of the college wifi
COLLEGE_SSID="IIT(BHU)"
# Change it to the UUID of the college wifi
COLLEGE_UUID="84aab8b1-7bda-4e94-bd52-06181ff6678f"
```

#### b) Edit `wifi-keepalive.sh`

Open the file:
```bash
nano wifi-keepalive.sh
```

Update these values:
1. **Line 4:** Change `wlan0` to your interface if different
2. **Line 7:** Change `IIT(BHU)` to your WiFi SSID if different

```bash
# Change it with your interface
IFACE="wlan0"

# Change this with your WiFi SSID
COLLEGE_SSID="IIT(BHU)"
```

#### c) Edit `wifi-login.sh`

Open the file:
```bash
nano wifi-login.sh
```

Update these values:
1. **Line 4:** Replace `yourusername` with your actual Linux username
2. **Line 16:** Replace `wlan0` with your interface if different
3. **Line 17:** Replace `IIT(BHU)` with your wifi SSID
3. **Line 18:** Change firewall URL if your network uses a different one

```bash
# Change this line:
ACTUAL_USER="yourusername"  # ← Your Linux username here

# First check interface with "ip link" and then change it
IFACE="wlan0"

# Change this with your wifi SSID
COLLEGE_SSID="IIT(BHU)"

# And this if needed:
FIREWALL_URL="http://192.168.249.1:1000"  # ← Your captive portal URL
```

To find your username:
```bash
whoami
```

### Step 5: Install the Scripts

Make all scripts executable:
```bash
chmod +x 90-wifi-login wifi-keepalive.sh wifi-login.sh
```

Copy scripts to system directories:
```bash
# Install NetworkManager dispatcher script
sudo cp 90-wifi-login /etc/NetworkManager/dispatcher.d/

# Install main scripts
sudo cp wifi-login.sh /usr/local/bin/
sudo cp wifi-keepalive.sh /usr/local/bin/

# Install systemd service and timer
sudo cp wifi-keepalive.service /etc/systemd/system/
sudo cp wifi-keepalive.timer /etc/systemd/system/
```

### Step 6: Enable the Services

Reload systemd and enable the timer:
```bash
sudo systemctl daemon-reload
sudo systemctl enable wifi-keepalive.timer
sudo systemctl start wifi-keepalive.timer
```

Restart NetworkManager to activate the dispatcher script:
```bash
sudo systemctl restart NetworkManager
```

### Step 7: Verify Installation

Check if the timer is active:
```bash
systemctl status wifi-keepalive.timer
systemctl list-timers | grep wifi-keepalive
```

You should see output showing the timer is active and the next run time.

## Configuration

### Adjusting Check Interval

The default keepalive check runs every 5 minutes. To change this:

Edit the timer file:
```bash
sudo nano /etc/systemd/system/wifi-keepalive.timer
```

Modify the `OnUnitActiveSec` value:
```ini
[Timer]
OnBootSec=2min           # Wait 2 minutes after boot
OnUnitActiveSec=5min     # Check every 5 minutes (change this)
```

Common intervals:
- Every 3 minutes: `OnUnitActiveSec=3min`
- Every 10 minutes: `OnUnitActiveSec=10min`
- Every 30 minutes: `OnUnitActiveSec=30min`

After changing, reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart wifi-keepalive.timer
```

### Changing WiFi Interface

If your WiFi interface, SSID and UUID is different, update all scripts:

```bash
# Find your interface
ip link show

# Update in all three files:
sudo nano /etc/NetworkManager/dispatcher.d/90-wifi-login
sudo nano /usr/local/bin/wifi-keepalive.sh
sudo nano /usr/local/bin/wifi-login.sh

# Replace all instances of "wlan0", "COLLEGE_SSID", "COLLEGE_UUID" accordingly
```

### Customizing Firewall URL

Different networks use different captive portal URLs. To find yours:

1. Connect to the WiFi without logging in
2. Open a browser and try to visit any website
3. You'll be redirected to a login page - copy that URL (only till port e.g. `http://192.168.249.1:1000`)
4. Update `FIREWALL_URL` in `wifi-login.sh`

## Usage

Once installed, the system works automatically:

### On Connection
When you connect to the configured WiFi network, you'll receive a notification:
- "Attempting to log in to IIT(BHU) WiFi network..."
- Then either "Successfully logged in" or "Failed to log in"

### Session Keepalive
Every 5 minutes (or your configured interval), the system checks if you're still authenticated. If your session expired, it automatically re-authenticates.

### Manual Testing

Test the login script manually:
```bash
sudo /usr/local/bin/wifi-login.sh
```

Test the keepalive script:
```bash
sudo /usr/local/bin/wifi-keepalive.sh
```

Run the dispatcher script manually:
```bash
sudo /etc/NetworkManager/dispatcher.d/90-wifi-login wlan0 up
```

## Troubleshooting

### Check Logs

View different log files:

```bash
# WiFi login attempts
tail -f /tmp/wifi-login.log

# Keepalive checks
tail -f /tmp/wifi-keepalive.log

# NetworkManager dispatcher events
tail -f /tmp/nm-dispatcher.log

# Watch all logs at once
tail -f /tmp/wifi-*.log /tmp/nm-dispatcher.log
```

View systemd journal:
```bash
# Keepalive service logs
journalctl -u wifi-keepalive.service -f

# NetworkManager logs
journalctl -u NetworkManager -f

# All logs since today
journalctl --since today | grep -i wifi
```

### Common Issues

#### 1. Script not running on connection
**Check:** Is the dispatcher script executable?
```bash
ls -l /etc/NetworkManager/dispatcher.d/90-wifi-login
```
Should show `-rwxr-xr-x` (executable).

**Fix:**
```bash
sudo chmod +x /etc/NetworkManager/dispatcher.d/90-wifi-login
sudo systemctl restart NetworkManager
```

#### 2. Notifications not appearing
**Check:** Desktop notification service running?
```bash
ps aux | grep notification
```

**Fix:** The script uses `sudo -u` to send notifications as your user. Ensure your username is correctly set in `wifi-login.sh`.

#### 3. "Connection was closed" error
**Check logs:**
```bash
tail -20 /tmp/wifi-login.log
```

**Common causes:**
- Network interface not ready (script will retry)
- Wrong firewall URL
- Captive portal changed its structure

**Fix:** Try connecting manually in browser first, then check if the login page structure changed.

#### 4. Timer not running
**Check status:**
```bash
systemctl status wifi-keepalive.timer
systemctl is-enabled wifi-keepalive.timer
```

**Fix:**
```bash
sudo systemctl enable wifi-keepalive.timer
sudo systemctl start wifi-keepalive.timer
```

#### 5. Wrong credentials
**Check config file:**
```bash
cat ~/.config/wifi-login.conf
```

**Fix:** Update credentials and make sure there are no extra spaces:
```bash
nano ~/.config/wifi-login.conf
# Ensure format is: USERNAME="your_username"
```

#### 6. Script runs but login fails
**Debug steps:**
1. Check if you can ping the firewall:
   ```bash
   ping -c 3 192.168.249.1
   ```

2. Check if captive portal is accessible:
   ```bash
   curl -I http://192.168.249.1:1000
   ```

3. Test manually in verbose mode:
   ```bash
   bash -x /usr/local/bin/wifi-login.sh
   ```

### Enable Detailed Debugging

Add this to the top of `wifi-login.sh` for more verbose output:
```bash
set -x  # Print each command before executing
```

Then check logs:
```bash
tail -100 /tmp/wifi-login.log
```

## Uninstallation

To completely remove the system:

```bash
# Stop and disable the timer
sudo systemctl stop wifi-keepalive.timer
sudo systemctl disable wifi-keepalive.timer

# Remove all files
sudo rm /etc/NetworkManager/dispatcher.d/90-wifi-login
sudo rm /usr/local/bin/wifi-login.sh
sudo rm /usr/local/bin/wifi-keepalive.sh
sudo rm /etc/systemd/system/wifi-keepalive.service
sudo rm /etc/systemd/system/wifi-keepalive.timer

# Remove logs (optional)
rm /tmp/wifi-*.log /tmp/nm-dispatcher.log

# Remove config (optional - contains your credentials!)
rm ~/.config/wifi-login.conf

# Reload systemd
sudo systemctl daemon-reload

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

## Customization

### For Different Networks

To adapt this for a different captive portal WiFi network:

1. **Find your network details:**
   - SSID (network name)
   - Connection UUID (`nmcli connection show`)
   - Captive portal URL (redirect URL when not logged in)

2. **Analyze the login form:**
   ```bash
   # Visit the captive portal in a browser
   # Open Developer Tools (F12) → Network tab
   # Perform a login manually
   # Look at the POST request to see what fields are sent
   ```

3. **Update `wifi-login.sh`:**
   - Change the parameters `IFACE`, `COLLEGE_SSID`, `FIREWALL_URL`
   - Modify the form fields in the `curl` POST request
   - Update field names like `USERNAME`, `PASSWORD`, `ACTUAL_USER`, etc.
   - Adjust the Whatever you want

4. **Update all IFACE and SSID references:**
   - In `90-wifi-login`, `wifi-login.sh`, `wifi-keepalive.sh`: Change "IIT(BHU)" and "wlan0" to your SSID and interface


5. **Update all UUID references:**
   - In `90-wifi-login`: Change "84aab8b1-7bda-4e94-bd52-06181ff6678f" to your UUID

### Adding Multiple Networks

To support multiple WiFi networks, modify the scripts to check for multiple SSIDs:

```bash
# In 90-wifi-login and wifi-keepalive.sh:
if [[ "$SSID" = "Network1" || "$SSID" = "Network2" ]]; then
    # Run login script
fi
```

### Changing Log Location

To change where logs are stored, update the redirect paths:

```bash
# In 90-wifi-login:
/usr/local/bin/wifi-login.sh >> /var/log/wifi-login.log 2>&1

# In wifi-keepalive.sh:
echo "..." >> /var/log/wifi-keepalive.log
```

Don't forget to ensure the directory is writable:
```bash
sudo touch /var/log/wifi-login.log
sudo chmod 666 /var/log/wifi-login.log
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Credentials File:** Your `~/.config/wifi-login.conf` contains plaintext credentials. Keep it secure:
   ```bash
   chmod 600 ~/.config/wifi-login.conf
   ```

2. **Root Access:** The scripts need root access to run automatically. Review the code before installation.

3. **Logs:** Log files may contain sensitive information. They're stored in `/tmp/` which is cleared on reboot.

4. **Git:** Never commit your `wifi-login.conf` file. Add it to `.gitignore`:
   ```bash
   echo "wifi-login.conf" >> .gitignore
   ```

## Contributing

Improvements and suggestions are welcome! If you find bugs or have feature requests:

1. Check existing issues
2. Open a new issue with details
3. Submit pull requests

## Credits

Created for IIT(BHU) WiFi automation. Adaptable for other captive portal networks.

---

**Last Updated:** 17 January 2026

For questions or issues, please open an issue on GitHub.