#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables
SERVICE_NAME="jobboss2-kiosk.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
ENV_FILE="/etc/jobboss2-kiosk.env"
LOG_FILE="/var/log/jobboss2-kiosk.log"
EXTENSION_DIR="$HOME/jobboss2-autologin/extension"
CONTENT_JS="$EXTENSION_DIR/content.js"
AUTOSTART_FILE="$HOME/.config/openbox/autostart"

# Function to log messages
log_message() {
    echo "\$1" | sudo tee -a $LOG_FILE
}

# Install necessary packages
echo "Installing necessary packages..."
sudo apt update
sudo apt install --no-install-recommends xorg openbox chromium whiptail -y

# Prompt for username and password
JOBBOSS_USER=$(whiptail --inputbox "Enter JobBoss username:" 8 40 --title "Username Input" 3>&1 1>&2 2>&3)
JOBBOSS_PASSWORD=$(whiptail --passwordbox "Enter JobBoss password:" 8 40 --title "Password Input" 3>&1 1>&2 2>&3)

# Check if the user pressed Cancel
if [ $? -ne 0 ]; then
    echo "User canceled the input."
    exit 1
fi

# Replace placeholders with actual credentials in content.js
echo "Updating content.js with credentials..."
sudo sed -i "s/USERNAME_PLACEHOLDER/$JOBBOSS_USER/g" "$CONTENT_JS"
sudo sed -i "s/PASSWORD_PLACEHOLDER/$JOBBOSS_PASSWORD/g" "$CONTENT_JS"

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

# Add startx to .bash_profile
BASH_PROFILE="$HOME/.bash_profile"
if ! grep -q "startx" "$BASH_PROFILE"; then
    echo 'if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then exec startx; fi' >> "$BASH_PROFILE"
fi

# Create .xinitrc file
XINITRC_FILE="$HOME/.xinitrc"
echo "Creating .xinitrc file..."
cat <<EOF > "$XINITRC_FILE"
#!/bin/bash
exec openbox-session
EOF
chmod +x "$XINITRC_FILE"

# Ensure Openbox autostart file exists
AUTOSTART_FILE="$HOME/.config/openbox/autostart"
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
# add chromium launch line to autostart
echo "/usr/bin/chromium http://192.168.1.64/jobboss2/t1/DataCollection --load-extension=$EXTENSION_DIR --kiosk & disown" >> "$AUTOSTART_FILE"

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling systemd service..."
sudo systemctl enable $SERVICE_NAME

# Start the service immediately
echo "Starting systemd service..."
sudo systemctl start $SERVICE_NAME

# Check the status of the service
echo "Checking systemd service status..."
sudo systemctl status $SERVICE_NAME --no-pager || true

# Schedule a daily restart at 1 AM with logging
echo "Scheduling daily restart at 1 AM with logging..."
(crontab -l 2>/dev/null; echo "0 1 * * * echo \"Restarting system at \$(date)\" | sudo tee -a $LOG_FILE && /sbin/shutdown -r now") | crontab -

log_message "Setup complete. Rebooting now..."

# Log the reboot action
echo "Rebooting system at $(date)" | sudo tee -a $LOG_FILE

# Reboot the system
sudo shutdown -r now
