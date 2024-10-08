#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
SERVICE_FILE="/etc/systemd/system/jobboss-autologin.service"
ENV_FILE="/etc/jobboss2-autologin.env"
LOG_FILE="/var/log/jobboss2-restart.log"
AUTOSTART_FILE="$HOME/.config/openbox/autostart"

# Function to log messages
log_message() {
    echo "\$1" | sudo tee -a $LOG_FILE
}

# Install necessary packages
echo "Installing necessary packages..."
sudo apt update
sudo apt install --no-install-recommends xorg openbox chromium chromium-driver python3-selenium whiptail -y

# Prompt for username and password
JOBBOSS_USER=$(whiptail --inputbox "Enter JobBoss username:" 8 40 --title "Username Input" 3>&1 1>&2 2>&3)
JOBBOSS_PASSWORD=$(whiptail --passwordbox "Enter JobBoss password:" 8 40 --title "Password Input" 3>&1 1>&2 2>&3)

# Check if the user pressed Cancel
if [ $? -ne 0 ]; then
    echo "User canceled the input."
    exit 1
fi

# Store credentials in a system-wide environment file
echo "Storing credentials..."
sudo bash -c "cat <<EOF > $ENV_FILE
JOBBOSS_USER='$JOBBOSS_USER'
JOBBOSS_PASSWORD='$JOBBOSS_PASSWORD'
EOF"

# Set permissions for the environment file
sudo chmod 644 $ENV_FILE

# Enable automatic login for the user
echo "Enabling automatic login..."
GETTY_OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
GETTY_OVERRIDE_FILE="$GETTY_OVERRIDE_DIR/override.conf"
sudo mkdir -p "$GETTY_OVERRIDE_DIR"
cat <<EOF | sudo tee "$GETTY_OVERRIDE_FILE" > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF

# Create .xinitrc file
XINITRC_FILE="$HOME/.xinitrc"
echo "Creating .xinitrc file..."
cat <<EOF > "$XINITRC_FILE"
#!/bin/bash
openbox-session &
sleep 2
/usr/bin/chromium --kiosk --noerrdialogs --disable-infobars --incognito http://192.168.1.64/jobboss2
EOF
chmod +x "$XINITRC_FILE"

if ! grep -q "startx" "$HOME/.bash_profile"; then
    echo "if [ -z \"\$DISPLAY\" ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then
        startx
    fi" >> "$HOME/.bash_profile"
fi

# Ensure Openbox autostart file exists
mkdir -p "$(dirname "$AUTOSTART_FILE")"
touch "$AUTOSTART_FILE"

# Add xset commands to Openbox autostart
echo "Configuring display power management settings..."
if ! grep -q "xset -dpms" "$AUTOSTART_FILE"; then
    echo "xset -dpms" >> "$AUTOSTART_FILE"
fi
if ! grep -q "xset s off" "$AUTOSTART_FILE"; then
    echo "xset s off" >> "$AUTOSTART_FILE"
fi

# Create the systemd service file
echo "Creating systemd service file..."
cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Auto login to jobboss2
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/$USER/jobboss2-autologin/autologin.py
User=$USER
Environment=DISPLAY=:0
EnvironmentFile=$ENV_FILE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling systemd service..."
sudo systemctl enable jobboss-autologin.service

# Start the service immediately
echo "Starting systemd service..."
sudo systemctl start jobboss-autologin.service

# Check the status of the service
echo "Checking systemd service status..."
sudo systemctl status jobboss-autologin.service --no-pager || true

# Schedule a daily restart at 1 AM with logging
echo "Scheduling daily restart at 1 AM with logging..."
(crontab -l 2>/dev/null; echo "0 1 * * * echo \"Restarting system at \$(date)\" | sudo tee -a $LOG_FILE && /sbin/shutdown -r now") | crontab -

log_message "Setup complete. Rebooting now..."

# Reboot the system
sudo shutdown -r now
