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

# 1. Stop and Disable System Service
echo -e "${BOLD}[1/4] Stopping background system service...${RESET}"
systemctl stop sys-guardian.service 2>/dev/null || true
systemctl disable sys-guardian.service 2>/dev/null || true
rm -f /etc/systemd/system/sys-guardian.service
systemctl daemon-reload
pkill -f sys-guardian-tray 2>/dev/null || true
pkill -f "systemd-inhibit.*Sys-Guardian" 2>/dev/null || true
echo -e "${GREEN}✓ Systemd system service stopped and removed.${RESET}"

# 2. Remove Executable Binaries
echo -e "\n${BOLD}[2/4] Removing executable binaries from /usr/local/bin...${RESET}"
rm -f /usr/local/bin/sys-guardian /usr/local/bin/sys-guardian-tray
echo -e "${GREEN}✓ Binaries removed.${RESET}"

# 3. Remove /etc Configs, Autostart, Completion, Polkit, and Man Page
echo -e "\n${BOLD}[3/4] Removing system integrations...${RESET}"
rm -f /etc/xdg/autostart/sys-guardian-tray.desktop
rm -f /etc/polkit-1/rules.d/99-sysguardian.rules
rm -f /etc/bash_completion.d/sys-guardian /usr/share/bash-completion/completions/sys-guardian
rm -rf /etc/sys-guardian
rm -f /usr/local/share/man/man1/sys-guardian.1
systemctl restart polkit 2>/dev/null || true
echo -e "${GREEN}✓ Autostart, /etc configurations, completion, and manual page removed.${RESET}"

# 4. Remove Runtime and State Files
echo -e "\n${BOLD}[4/4] Cleaning runtime states...${RESET}"
rm -rf /run/sys-guardian /tmp/sys-guardian* /tmp/sys-guardian-report.txt

echo -e "\n${GREEN}${BOLD}✓ Sys-Guardian successfully uninstalled from the system.${RESET}"
echo -e "(Incident history in /var/log/sys-guardian/ was preserved. Remove manually if desired)."
