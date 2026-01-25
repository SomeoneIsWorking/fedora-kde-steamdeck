#!/bin/bash
# Detect the real user if running with sudo
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "Setting up for user: $REAL_USER"

# Remove shortcut from user home and root home
rm -f "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop"
sudo rm -f "/root/.local/share/applications/switch-to-gamemode.desktop"

# 2. INSTALL DEPENDENCIES
sudo dnf install gamescope -y

# 3. CREATE NATIVE SESSION
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/steam-gamemode.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Steam Gamemode
Comment=Direct Gamescope Session
Exec=env XDG_CURRENT_DESKTOP=gamescope gamescope -e -f --hide-cursor-delay 3000 -- steam -gamepadui -steamos3
Type=Application
DesktopNames=gamescope
EOF

# 4. CONFIGURE AUTO-LOGIN
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/zz-steamos-autologin.conf > /dev/null <<EOF
[Autologin]
User=$REAL_USER
Relogin=false
EOF

# 5. CREATE PRIVILEGED HELPER SCRIPT
sudo tee /usr/bin/steamos-priv-helper > /dev/null <<EOF
#!/bin/bash
STATE_FILE="/var/lib/sddm/state.conf"
AUTO_CONF="/etc/sddm.conf.d/zz-steamos-autologin.conf"
ACTION=\$1

if [[ "\$ACTION" == "plasma" ]]; then
    /usr/bin/sed -i 's/Session=.*/Session=plasma/' "\$STATE_FILE"
    /usr/bin/grep -q "Session=" "\$AUTO_CONF" && sed -i 's/Session=.*/Session=plasma/' "\$AUTO_CONF" || echo "Session=plasma" >> "\$AUTO_CONF"
elif [[ "\$ACTION" == "steam-gamemode" ]]; then
    /usr/bin/sed -i 's/Session=.*/Session=steam-gamemode/' "\$STATE_FILE"
    /usr/bin/grep -q "Session=" "\$AUTO_CONF" && sed -i 's/Session=.*/Session=steam-gamemode/' "\$AUTO_CONF" || echo "Session=steam-gamemode" >> "\$AUTO_CONF"
fi

# Immediate restart to force session change
/usr/bin/systemctl restart sddm
EOF
sudo chmod 755 /usr/bin/steamos-priv-helper
sudo chown root:root /usr/bin/steamos-priv-helper

# 6. CONFIGURE SUDOERS
sudo tee /etc/sudoers.d/gamemode-switch > /dev/null <<EOF
$REAL_USER ALL=(ALL) NOPASSWD: /usr/bin/steamos-priv-helper
EOF
sudo chmod 440 /etc/sudoers.d/gamemode-switch

# 7. SESSION SELECTOR
sudo tee /usr/bin/steamos-session-select > /dev/null <<EOF
#!/bin/bash
if [[ "\$XDG_CURRENT_DESKTOP" == *"gamescope"* ]]; then
    /usr/bin/killall -9 steam gamescope
    /usr/bin/sudo /usr/bin/steamos-priv-helper plasma
else
    /usr/bin/sudo /usr/bin/steamos-priv-helper steam-gamemode
fi
EOF
sudo chmod +x /usr/bin/steamos-session-select

# 8. SHORTCUT
mkdir -p "$REAL_HOME/.local/share/applications"
tee "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop" > /dev/null <<EOF
[Desktop Entry]
Name=Switch to Gamemode
Exec=/usr/bin/steamos-session-select
Icon=steam-launcher
Type=Application
Terminal=false
Categories=System;
EOF

chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop"
sudo -u "$REAL_USER" update-desktop-database "$REAL_HOME/.local/share/applications/"

# 9. PERFORMANCE CAPS
sudo setcap 'cap_sys_nice=eip' $(which gamescope)

echo "Done. Service removed. Reverted to SDDM restart method."