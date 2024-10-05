#!/bin/bash

# Variables
SERVICE_FILE="/etc/systemd/system/jobboss-autologin.service"
GETTY_OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
GETTY_OVERRIDE_FILE="$GETTY_OVERRIDE_DIR/override.conf"
XINITRC_FILE="$HOME/.xinitrc"
ENV_FILE="$HOME/.jobboss_env"
REPO_DIR="$HOME/jobboss2-autologin"
AUTLOGIN_SCRIPT="$REPO_DIR/autologin.py"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to install necessary packages
install_packages() {
    echo -e "${YELLOW}Installing necessary packages...${NC}"
    sudo apt update -qq && sudo apt install --no-install-recommends xorg openbox chromium chromium-driver python3-selenium -y -qq
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Packages installed successfully.${NC}"
    else
        echo -e "${RED}Failed to install packages.${NC}"
        exit 1
    fi
}

# Function to prompt for credentials and store them
store_credentials() {
    read -p "Enter JobBoss username: " JOBBOSS_USER
    read -sp "Enter JobBoss password: " JOBBOSS_PASSWORD
    echo

    echo -e "${YELLOW}Storing credentials...${NC}"
    cat <<EOF > "$ENV_FILE"
export JOBBOSS_USER='$JOBBOSS_USER'
export JOBBOSS_PASSWORD='$JOBBOSS_PASSWORD'
EOF

    if ! grep -q ". $ENV_FILE" "$HOME/.bash_profile"; then
        echo ". $ENV_FILE" >> "$HOME/.bash_profile"
    fi
    echo -e "${GREEN}Credentials stored successfully.${NC}"
}

# Function to enable automatic login
enable_auto_login() {
    echo -e "${YELLOW}Enabling automatic login...${NC}"
    sudo mkdir -p "$GETTY_OVERRIDE_DIR"
    cat <<EOF | sudo tee "$GETTY_OVERRIDE_FILE" > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
    echo -e "${GREEN}Automatic login enabled.${NC}"
}

# Function to create .xinitrc file
create_xinitrc() {
    echo -e "${YELLOW}Creating .xinitrc file...${NC}"
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
    echo -e "${GREEN}.xinitrc file created.${NC}"
}

# Function to create systemd service
create_systemd_service() {
    echo -e "${YELLOW}Creating systemd service file...${NC}"
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
    echo -e "${GREEN}Systemd service created and started.${NC}"
    sudo systemctl status jobboss-autologin.service --no-pager
}

# Main script execution
install_packages
store_credentials
enable_auto_login
create_xinitrc
create_systemd_service
