#!/usr/bin/env bash
# ==============================================================================
# Sys-Guardian System Uninstaller
# Clean Removal Script
# Repository: https://github.com/DriveMegaOrigin/sys-guardian
# ==============================================================================

set -e

RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${RED}${BOLD}"
echo "  🗑️  Sys-Guardian System Service Uninstaller"
echo "  ------------------------------------------"
echo -e "${RESET}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Removing system services requires root privileges.${RESET}"
    echo -e "Please run: ${BOLD}sudo ./uninstall.sh${RESET}"
    exit 1
fi

# 1. Stop and Disable System and User Services, Kill Running Processes
echo -e "${BOLD}[1/4] Stopping background services and processes...${RESET}"
systemctl stop sys-guardian.service 2>/dev/null || true
systemctl disable sys-guardian.service 2>/dev/null || true
rm -f /etc/systemd/system/sys-guardian.service
systemctl daemon-reload

# Kill all daemon, tray, and inhibitor processes
pkill -f "systemd-inhibit.*Sys-Guardian" 2>/dev/null || true
pkill -f "sys-guardian-tray" 2>/dev/null || true
pkill -f "sys-guardian" 2>/dev/null || true

# Clean legacy user services if present
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_UID=$(id -u "$SUDO_USER" 2>/dev/null)
    sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$TARGET_UID" systemctl --user stop sys-guardian.service sys-guardian-tray.service 2>/dev/null || true
    sudo -u "$SUDO_USER" XDG_RUNTIME_DIR="/run/user/$TARGET_UID" systemctl --user disable sys-guardian.service sys-guardian-tray.service 2>/dev/null || true
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    rm -f "$TARGET_HOME/.config/systemd/user/sys-guardian.service" "$TARGET_HOME/.config/systemd/user/sys-guardian-tray.service"
    rm -f "$TARGET_HOME/.config/autostart/sys-guardian-tray.desktop"
    rm -rf "$TARGET_HOME/.local/share/sys-guardian"
fi
echo -e "${GREEN}✓ All services stopped and processes terminated.${RESET}"

# 2. Remove Executable Binaries
echo -e "\n${BOLD}[2/4] Removing executable binaries from /usr/local/bin...${RESET}"
rm -f /usr/local/bin/sys-guardian /usr/local/bin/sys-guardian-tray
echo -e "${GREEN}✓ Binaries removed.${RESET}"

# 3. Remove /etc Configs, Autostart, Completion, Polkit, and Man Page
echo -e "\n${BOLD}[3/4] Removing system integrations...${RESET}"
rm -f /etc/xdg/autostart/sys-guardian-tray.desktop
rm -f /etc/polkit-1/rules.d/99-sysguardian.rules
rm -f /etc/bash_completion.d/sys-guardian /usr/share/bash-completion/completions/sys-guardian
rm -f /etc/profile.d/sys-guardian.sh
rm -rf /etc/sys-guardian
rm -f /usr/local/share/man/man1/sys-guardian.1
command -v mandb >/dev/null 2>&1 && mandb -q 2>/dev/null || true
systemctl restart polkit 2>/dev/null || true
echo -e "${GREEN}✓ Autostart, /etc configurations, completion, polkit rule, and manual page removed.${RESET}"

# 4. Remove Runtime, Logs, and State Files
echo -e "\n${BOLD}[4/4] Cleaning runtime states and logs...${RESET}"
rm -rf /run/sys-guardian /var/log/sys-guardian /tmp/sys-guardian* /tmp/sys-guardian-report.txt /run/user/*/sys-guardian*

echo -e "\n${GREEN}${BOLD}==================================================${RESET}"
echo -e "${GREEN}${BOLD}✓ Sys-Guardian was completely uninstalled!${RESET}"
echo -e "${GREEN}${BOLD}==================================================${RESET}"
echo -e "All services, binaries, polkit rules, configurations, and logs were removed 100%."
