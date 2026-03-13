#!/bin/bash
set -euo pipefail

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "Cleaning up..."

# Remove session entry created by install.sh
sudo rm -f /usr/share/wayland-sessions/steam-picker.desktop

# Remove launcher shortcut created by install.sh
rm -f "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop"

# Remove session state used by install.sh
rm -f "$REAL_HOME/.gamemode-session-flag"

# Remove scripts created by install.sh
sudo rm -f /usr/bin/steamos-switch-to-steam
sudo rm -f /usr/bin/steamos-session-picker
sudo rm -f /usr/bin/steamos-session-select

if [[ -d "$REAL_HOME/.local/share/applications" ]]; then
    sudo -u "$REAL_USER" update-desktop-database "$REAL_HOME/.local/share/applications/"
fi

echo "Cleanup complete."
