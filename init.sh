#!/bin/bash

# Variables
SERVICE_FILE="/etc/systemd/system/jobboss-autologin.service"
GETTY_OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
GETTY_OVERRIDE_FILE="$GETTY_OVERRIDE_DIR/override.conf"
XINITRC_FILE="$HOME/.xinitrc"
ENV_FILE="$HOME/.jobboss_env"
REPO_DIR="$HOME/jobboss2-autologin"
AUTLOGIN_SCRIPT="$REPO_DIR/autologin.py"

# Function to install necessary packages
install_packages() {
    whiptail --title "Package Installation" --infobox "Installing necessary packages..." 8 40
    sudo apt update -qq && sudo apt install --no-install-recommends xorg openbox chromium chromium-driver python3-selenium -y -qq
    if [ $? -eq 0 ]; then
        whiptail --title "Success" --msgbox "Packages installed successfully." 8 40
    else
        whiptail --title "Error" --msgbox "Failed to install packages." 8 40
        exit 1
    fi
}

# Function to prompt for credentials and store them
store_credentials() {
    JOBBOSS_USER=$(whiptail --inputbox "Enter JobBoss username:" 8 40 --title "Username Input" 3>&1 1>&2 2>&3)
    JOBBOSS_PASSWORD=$(whiptail --passwordbox "Enter JobBoss password:" 8 40 --title "Password Input" 3>&1 1>&2 2>&3)

    whiptail --title "Storing Credentials" --infobox "Storing credentials..." 8 40
    cat <<EOF > "$ENV_FILE"
export JOBBOSS_USER='$JOBBOSS_USER'
export JOBBOSS_PASSWORD='$JOBBOSS_PASSWORD'
EOF

    if ! grep -q ". $ENV_FILE" "$HOME/.bash_profile"; then
        echo ". $ENV_FILE" >> "$HOME/.bash_profile"
    fi
}

# Function to enable automatic login
enable_auto_login() {
    whiptail --title "Auto Login" --infobox "Enabling automatic login..." 8 40
    sudo mkdir -p "$GETTY_OVERRIDE_DIR"
    cat <<EOF | sudo tee "$GETTY_OVERRIDE_FILE" > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
}

# Function to create .xinitrc file
create_xinitrc() {
    whiptail --title "Xinit Configuration" --infobox "Creating .xinitrc file..." 8 40
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
}

# Function to create systemd service
create_systemd_service() {
    whiptail --title "Systemd Service" --infobox "Creating systemd service file..." 8 40
    cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Auto login to jobboss2
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $AUTLOGIN_SCRIPT
User=$USER
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable jobboss-autologin.service
    sudo systemctl start jobboss-autologin.service
    whiptail --title "Service Status" --msgbox "$(systemctl status jobboss-autologin.service --no-pager)" 20 60
}

# Main script execution
install_packages
store_credentials
enable_auto_login
create_xinitrc
create_systemd_service
