#!/bin/bash
set -euo pipefail

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "Setting up simple session switching for user: $REAL_USER"

# 1. Session picker script (reads flag and launches session)
sudo tee /usr/bin/steamos-session-picker > /dev/null <<'PICKER_EOF'
#!/bin/bash
set -euo pipefail

STATE_FILE="$HOME/.gamemode-session-flag"
if [[ -f "$STATE_FILE" ]]; then
    LOG_FILE="$HOME/.local/state/steamos-session-picker.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    # Force composition and disable HDR signaling for cleaner remote-stream colors.
    gamescope -e -f --force-composition --sdr-gamut-wideness 0 --hide-cursor-delay 3000 -- steam -gamepadui -steamos3 >>"$LOG_FILE" 2>&1
    EXIT_CODE=$?

    echo "$(date -Is) gamescope exited with code ${EXIT_CODE}, falling back to Plasma" >>"$LOG_FILE"
    rm -f "$STATE_FILE"
    exec startplasma-wayland
else
    exec startplasma-wayland
fi
PICKER_EOF
sudo chmod +x /usr/bin/steamos-session-picker

# 2. Session entry that always uses picker logic
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/steam-picker.desktop > /dev/null <<'SESS_EOF'
[Desktop Entry]
Name=Steam Session Picker
Comment=Launch Steam or Plasma based on the session flag
Exec=/usr/bin/steamos-session-picker
Type=Application
DesktopNames=gamescope
SESS_EOF

# 3. Switch from Plasma to Steam session
sudo tee /usr/bin/steamos-switch-to-steam > /dev/null <<'TO_STEAM_EOF'
#!/bin/bash
set -euo pipefail

touch "$HOME/.gamemode-session-flag"

if command -v qdbus-qt6 >/dev/null 2>&1; then
    qdbus-qt6 org.kde.Shutdown /Shutdown logout
elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.Shutdown /Shutdown logout
else
    loginctl terminate-session "$XDG_SESSION_ID"
fi
TO_STEAM_EOF
sudo chmod +x /usr/bin/steamos-switch-to-steam

# 4. Steam's "Switch to Desktop" integration expects this command name.
sudo tee /usr/bin/steamos-session-select > /dev/null <<'SESSION_SELECT_EOF'
#!/bin/bash
set -euo pipefail

rm -f "$HOME/.gamemode-session-flag"

killall -SIGTERM steam gamescope >/dev/null 2>&1 || true
SESSION_SELECT_EOF
sudo chmod +x /usr/bin/steamos-session-select

# 5. Plasma launcher
mkdir -p "$REAL_HOME/.local/share/applications"
tee "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop" > /dev/null <<'APP_EOF'
[Desktop Entry]
Name=Switch to Gamemode
Exec=/usr/bin/steamos-switch-to-steam
Icon=steam-launcher
Type=Application
Categories=System;
APP_EOF

chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.local/share/applications/switch-to-gamemode.desktop"
sudo -u "$REAL_USER" update-desktop-database "$REAL_HOME/.local/share/applications/"

echo "Done. Simple session switching installed."
