#!/bin/bash

# Variables
SERVICE_FILE="/etc/systemd/system/jobboss-autologin.service"

# Install necessary packages
echo "Installing necessary packages..."
sudo apt update
sudo apt install --no-install-recommends xorg openbox chromium chromium-driver python3-selenium -y

# Prompt for username and password
read -p "Enter JobBoss username: " JOBBOSS_USER
read -sp "Enter JobBoss password: " JOBBOSS_PASSWORD
echo

# Store credentials in a file
echo "export JOBBOSS_USER='$JOBBOSS_USER'" >> ~/.jobboss_env
echo "export JOBBOSS_PASSWORD='$JOBBOSS_PASSWORD'" >> ~/.jobboss_env

# Source the environment variables in .bash_profile
if ! grep -q ". ~/.jobboss_env" ~/.bash_profile; then
    echo ". ~/.jobboss_env" >> ~/.bash_profile
fi

# Enable automatic login for the use
echo "Enabling automatic login..."

# Create the override directory if it doesn't exist
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create the override file
echo "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM" | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf

# Create .xinit file
echo "#!/bin/bash
openbox-session &
sleep 2
/usr/bin/chromium --kiosk --noerrdialogs --disable-infobars --incognito http://192.168.1.64/jobboss2" | tee ~/.xinitrc

# Make .xinit file executable
chmod +x ~/.xinitrc

# Add startx to .bash_profile if not already present
if ! grep -q "startx" ~/.bash_profile; then
    echo "if [ -z \"\$DISPLAY\" ] && [ \"\$(tty)\" = \"/dev/tty1\" ]; then
        startx
    fi" >> ~/.bash_profile
fi

# Create the systemd service file
echo "Creating systemd service file..."
echo "[Unit]
Description=Auto login to jobboss2
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/$USER/jobbos2-autologin/autologin.py
User=$USER
Environment=DISPLAY=:0

[Install]
WantedBy=default.target" | sudo tee $SERVICE_FILE

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable jobboss-autologin.service

# Start the service immediately
sudo systemctl start jobboss-autologin.service

# Check the status of the service
sudo systemctl status jobboss-autologin.service
