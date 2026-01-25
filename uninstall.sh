#!/bin/bash

# Detect the real user
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "Uninstalling Steam Gamemode setup for user: $REAL_USER"

# 1. STOP AND REMOVE SYSTEMD SERVICE (if it exists)
echo "Removing background services..."
sudo systemctl stop steamos-autologin-helper 2>/dev/null
sudo systemctl disable steamos-autologin-helper 2>/dev/null
sudo rm -f /etc/systemd/system/steamos-autologin-helper.service
sudo systemctl daemon-reload

# 2. REMOVE BINARIES AND HELPERS
echo "Removing helper scripts..."
sudo rm -f /usr/bin/steamos-priv-helper
sudo rm -f /usr/bin/steamos-session-select

# 3. REMOVE SESSION DEFINITIONS
echo "Removing Wayland session files..."
sudo rm -f /usr/share/wayland-sessions/steam-gamemode.desktop

# 4. REMOVE SDDM CONFIGURATIONS
echo "Reverting SDDM configurations..."
sudo rm -f /etc/sddm.conf.d/zz-steamos-autologin.conf
# Note: We don't delete /var/lib/sddm/state.conf but we can reset it to plasma
if [ -f /var/lib/sddm/state.conf ]; then
    sudo sed -i 's/Session=.*/Session=plasma/' /var/lib/sddm/state.conf
fi

# 5. REMOVE SUDOERS RULE
echo "Removing sudoers permissions..."
sudo rm -f /etc/sudoers.d/gamemode-switch

# 6. REMOVE DESKTOP SHORTCUTS
echo "Removing application shortcuts..."
rm -f "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop"
sudo update-desktop-database "$REAL_HOME/.local/share/applications/" 2>/dev/null

echo "------------------------------------------------"
echo "Uninstall complete."
echo "Note: gamescope was not uninstalled. Use 'sudo dnf remove gamescope' if desired."
echo "It is recommended to restart SDDM or reboot now."