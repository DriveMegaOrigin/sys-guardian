#!/usr/bin/env bash
# ==============================================================================
# Sys-Guardian System Installer
# Standard /etc System Daemon Installation
# Repository: https://github.com/DriveMegaOrigin/sys-guardian
# ==============================================================================

set -e

# ANSI Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
echo "  🛡️  Sys-Guardian System Service Installer"
echo "  ----------------------------------------"
echo -e "${RESET}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Require Root / Sudo
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Installing a system service into /etc requires root privileges.${RESET}"
    echo -e "Please run: ${BOLD}sudo ./install.sh${RESET}"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(loginctl list-sessions --no-legend 2>/dev/null | awk '$3 != "root" && $3 != "" {print $3}' | head -n 1)}"
[ -z "$REAL_USER" ] && REAL_USER="root"

echo -e "${BOLD}[1/6] Checking system dependencies...${RESET}"
for cmd in systemctl journalctl awk grep sed python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}Error: Missing dependency '$cmd'. Please install it first.${RESET}"
        exit 1
    fi
done

if ! python3 -c "import gi; from gi.repository import GLib, Gio" >/dev/null 2>&1; then
    echo -e "${YELLOW}Notice: PyGObject (GLib/Gio) is not detected for python3.${RESET}"
    echo -e "The systray applet requires PyGObject. Install it if needed:"
    echo -e "  - Debian/Ubuntu: sudo apt install python3-gi"
    echo -e "  - Arch Linux:    sudo pacman -S python-gobject"
    echo -e "  - Fedora:        sudo dnf install python3-gobject"
fi
echo -e "${GREEN}✓ System dependencies verified.${RESET}"

# 2. Clean Up Any Old Broken Links
echo -e "\n${BOLD}[2/6] Cleaning legacy configurations...${RESET}"
pkill -f "systemd-inhibit.*Sys-Guardian" 2>/dev/null || true
if [ -L "/usr/local/bin/sys-guardian" ]; then
    rm -f /usr/local/bin/sys-guardian
fi
if [ -L "/usr/local/bin/sys-guardian-tray" ]; then
    rm -f /usr/local/bin/sys-guardian-tray
fi
# Stop old user services if present
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" systemctl --user stop sys-guardian.service sys-guardian-tray.service 2>/dev/null || true
    sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$SUDO_USER")" systemctl --user disable sys-guardian.service sys-guardian-tray.service 2>/dev/null || true
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    rm -f "$TARGET_HOME/.config/systemd/user/sys-guardian.service" "$TARGET_HOME/.config/systemd/user/sys-guardian-tray.service"
fi
echo -e "${GREEN}✓ Cleaned legacy units and symlinks.${RESET}"

# 3. Install Executable Binaries directly to /usr/local/bin (Full Permissions)
echo -e "\n${BOLD}[3/6] Installing executable binaries into /usr/local/bin...${RESET}"
install -m 755 "$SCRIPT_DIR/bin/sys-guardian" /usr/local/bin/sys-guardian
install -m 755 "$SCRIPT_DIR/bin/sys-guardian-tray" /usr/local/bin/sys-guardian-tray

echo -e "${GREEN}✓ Installed /usr/local/bin/sys-guardian (mode 755)${RESET}"
echo -e "${GREEN}✓ Installed /usr/local/bin/sys-guardian-tray (mode 755)${RESET}"

# 4. Install Systemd Service into /etc/systemd/system/
echo -e "\n${BOLD}[4/6] Installing systemd daemon into /etc/systemd/system/...${RESET}"
install -m 644 "$SCRIPT_DIR/systemd/sys-guardian.service" /etc/systemd/system/sys-guardian.service

# Setup Runtime & Log directories
mkdir -p /var/log/sys-guardian /run/sys-guardian
chmod 755 /var/log/sys-guardian /run/sys-guardian

systemctl daemon-reload
systemctl enable --now sys-guardian.service
echo -e "${GREEN}✓ System service enabled and started at boot (/etc/systemd/system/sys-guardian.service)${RESET}"

# 5. Configure Desktop Systray Autostart for GUI Sessions
echo -e "\n${BOLD}[5/6] Configuring Desktop Tray Autostart (/etc/xdg/autostart)...${RESET}"
mkdir -p /etc/xdg/autostart
install -m 644 "$SCRIPT_DIR/autostart/sys-guardian-tray.desktop" /etc/xdg/autostart/sys-guardian-tray.desktop

# Launch tray applet immediately for active desktop user if available and not already running
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_UID="$(id -u "$SUDO_USER")"
    if ! pgrep -u "$TARGET_UID" -f "sys-guardian-tray" >/dev/null 2>&1; then
        sudo -u "$SUDO_USER" \
            XDG_RUNTIME_DIR="/run/user/$TARGET_UID" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$TARGET_UID/bus" \
            nohup /usr/local/bin/sys-guardian-tray >/dev/null 2>&1 &
    fi
fi
echo -e "${GREEN}✓ Desktop systray registered (/etc/xdg/autostart/sys-guardian-tray.desktop)${RESET}"

# 6. Central Config & Bash Autocompletion (/etc/ or /usr/share/)
echo -e "\n${BOLD}[6/7] Installing /etc configuration and bash completion...${RESET}"
mkdir -p /etc/sys-guardian
if [ ! -f "/etc/sys-guardian/sys-guardian.conf" ]; then
    install -m 644 "$SCRIPT_DIR/etc/sys-guardian.conf" /etc/sys-guardian/sys-guardian.conf
    echo -e "${GREEN}✓ Created configuration in /etc/sys-guardian/sys-guardian.conf${RESET}"
else
    echo -e "${CYAN}ℹ Preserved existing /etc/sys-guardian/sys-guardian.conf${RESET}"
fi

COMP_DIR="/etc/bash_completion.d"
if [ -d "/usr/share/bash-completion/completions" ]; then
    COMP_DIR="/usr/share/bash-completion/completions"
fi
mkdir -p "$COMP_DIR"
install -m 644 "$SCRIPT_DIR/completions/sys-guardian" "$COMP_DIR/sys-guardian"
echo -e "${GREEN}✓ Installed bash completion in $COMP_DIR/sys-guardian${RESET}"

# 7. Manual Page & Polkit Compatibility Rule
echo -e "\n${BOLD}[7/7] Installing manual page and power protection rules...${RESET}"
if [ -d "/usr/local/share/man/man1" ] || mkdir -p "/usr/local/share/man/man1"; then
    install -m 644 "$SCRIPT_DIR/man/sys-guardian.1" /usr/local/share/man/man1/sys-guardian.1 2>/dev/null || true
    command -v mandb >/dev/null 2>&1 && mandb -q 2>/dev/null || true
    echo -e "${GREEN}✓ Manual page installed (run: man sys-guardian)${RESET}"
fi

if [ -d "/etc/polkit-1/rules.d" ]; then
    install -m 644 "$SCRIPT_DIR/polkit/99-sysguardian.rules" /etc/polkit-1/rules.d/99-sysguardian.rules 2>/dev/null || true
    systemctl restart polkit 2>/dev/null || true
    echo -e "${GREEN}✓ Polkit power protection rule active (/etc/polkit-1/rules.d/)${RESET}"
fi

echo -e "\n${GREEN}${BOLD}==================================================${RESET}"
echo -e "${GREEN}${BOLD}🎉 Sys-Guardian System Service Successfully Installed!${RESET}"
echo -e "${GREEN}${BOLD}==================================================${RESET}"

echo -e "\n${BOLD}Quick Verification:${RESET}"
echo -e "  ${CYAN}sys-guardian status${RESET}        - Check system integrity & power locks"
echo -e "  ${CYAN}sys-guardian diagnose${RESET}      - Hardware, GPU, and VM triage"
echo -e "  ${CYAN}sys-guardian test${RESET}          - Send a test alert to your desktop"
echo -e "  ${CYAN}sys-guardian simulate gpu${RESET}  - Simulate a GPU bus-drop event"
echo -e "  ${CYAN}sys-guardian log-last${RESET}      - View the persistent Blackbox (/var/log/sys-guardian/)"
echo -e "  ${CYAN}sys-guardian unblock${RESET}       - Clear any active power lock"
