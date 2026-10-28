<div align="center">

# 🛡️ Sys-Guardian

**Ultra-lightweight system-wide hardware integrity monitor, crash detector, and reboot protector for Linux.**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://kernel.org)
[![Shell](https://img.shields.io/badge/Shell-Bash%204%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Init](https://img.shields.io/badge/Init-systemd-red.svg)](https://systemd.io/)

</div>

---

## 📌 Why Sys-Guardian?

If you run **GPU Passthrough (VFIO/QEMU)**, discrete graphics cards (NVIDIA/AMD), or manage Linux workstations, you know this horror story:
1. A graphics card crashes or drops off the PCI bus (`fallen off the bus` or `Xid` error), or a virtual machine enters an unresponsive state.
2. The system seems to keep working, but attempting to reboot normally leads to a **hard freeze, black screen with fans spinning at 100%, and ungraceful power cutoff**.
3. Rebooting while a package manager (`apt`, `dpkg`, `pacman`, `dnf`) is updating in the background corrupts package databases.

**Sys-Guardian** runs as a native system service in `/etc/systemd/system/` to solve this:
* ⚡ **Instant Detection (< 1s)**: Continuously listens to kernel log events using zero-overhead inotify (`journalctl -f`), catching GPU and hardware crashes the second they happen.
* 🛑 **Native `systemd-inhibit` Protection**: Takes an inhibitor lock (`systemd-inhibit`). In KDE Plasma and GNOME, shutdown/reboot buttons display an interactive prompt: *"Sys-Guardian is preventing shutdown: [Reason]. Shut down anyway?"* — eliminating frustrating hard locks and silent freezes.
* 🖥️ **Desktop Systray Applet**: Automatically launches a discrete tray icon on your desktop panel: **🟢 Green Shield** when healthy, **🔴 Red Shield** with alert tooltips and quick triage menus when compromised.
* 📦 **Persistent Blackbox (2 Records)**: Keeps only the last 2 crash reports in `/var/log/sys-guardian/`. Unlike `/tmp` (which gets wiped on reboot), you can always inspect what caused the crash with `sys-guardian log-last`.
* 🪶 **Ultra-lightweight**: Pure Bash and Linux native interfaces (`sysfs`, `procfs`, `systemd`). Consumes **< 0.1% CPU** and **< 15MB RAM** combined.

---

## 🚀 1-Click System Installation

Clone the repository and run the installer with `sudo`:

```bash
git clone https://github.com/DriveMegaOrigin/sys-guardian.git
cd sys-guardian
sudo ./install.sh
```

The installer automatically:
- Installs `sys-guardian` and `sys-guardian-tray` directly into `/usr/local/bin/` with mode `755`.
- Configures and enables the system daemon in `/etc/systemd/system/sys-guardian.service` (starts automatically at boot).
- Sets up desktop autostart in `/etc/xdg/autostart/sys-guardian-tray.desktop` for all graphical users.
- Creates the persistent Blackbox log directory in `/var/log/sys-guardian/`.
- Installs the official manual page (`man sys-guardian`).

---

## 📖 CLI Command Reference

`sys-guardian` includes a full-featured, colorized terminal suite:

```bash
sys-guardian <COMMAND>
```

| Command | Description |
| :--- | :--- |
| `sys-guardian status` | Check current health status (**🟢 NORMAL** or **🔴 BLOCKED**). |
| `sys-guardian check` | Run an immediate one-shot scan across all sensors and logs. |
| `sys-guardian diagnose` | Deep triage: GPUs, VFIO drivers, zombie VMs, locks, and thermals. |
| `sys-guardian simulate gpu` | Inject a test GPU bus-drop event into kernel logs to verify detection. |
| `sys-guardian simulate oom` | Inject a test OOM killer event to verify memory pressure detection. |
| `sys-guardian simulate io` | Inject a test storage block I/O error into kernel logs. |
| `sys-guardian log-last` | Display the latest crash report from `/var/log/sys-guardian/crash_latest.log`. |
| `sys-guardian log-prev` | Display the preceding crash report from the Blackbox. |
| `sys-guardian unblock` | Manually dismiss the shutdown/reboot lock to allow system power actions. |
| `sys-guardian test` | Send a test desktop alert to the active graphical session. |
| `sys-guardian daemon` | Run the continuous background listener (< 1s latency). |
| `sys-guardian help` | Display the built-in help screen. |

---

## 🔍 Diagnostic Triage Example

Running `sys-guardian diagnose` gives you an instant overview of your hardware and virtualization layer:

```text
==================================================
🔍 SYS-GUARDIAN SYSTEM DIAGNOSTIC TRIAGE
==================================================

1. [GPU Hardware & Kernel Modules]:
00:02.0 VGA compatible controller: Intel Corporation TigerLake-H GT1 [UHD Graphics] (driver: i915)
01:00.0 VGA compatible controller: NVIDIA Corporation GA107GLM [RTX A2000 Mobile] (driver: nvidia)

2. [QEMU / KVM Virtual Machines]:
No QEMU virtual machine processes currently running.

3. [Package Manager Locks]:
No active package manager locks detected.

4. [Thermal Readings]:
  - thermal_zone0: 45°C
  - thermal_zone1: 42°C

5. [Power / Shutdown Protection Status]:
🟢 FREE (No active power inhibitors).
==================================================
```

---

## 🛡️ Monitored Subsystems

| Subsystem | What it monitors | Action on Failure |
| :--- | :--- | :--- |
| **🎮 GPU & VFIO** | `NVRM: Xid`, `fallen off the bus`, AMDGPU reset, GPU hang, QEMU crashes. | Instant alert + Shutdown lock |
| **📦 Package Managers** | Active `apt`, `dpkg`, `pacman`, `dnf` processes. | Instant alert + Shutdown lock |
| **💾 Storage & Filesystem** | Kernel block I/O errors (`EXT4-fs`, `BTRFS: error`, buffer I/O). | Instant alert + Shutdown lock |
| **💽 Root Disk Capacity** | Partitions reaching ≥ 90% capacity. | Warning alert |
| **🌡️ Thermal Protection** | Direct reading from `/sys/class/thermal/` (> 92°C). | Hardware warning alert |
| **🧠 Memory Pressure** | Linux PSI (`/proc/pressure/memory`) stall detection before OOM freeze. | Pre-OOM thrashing warning |

---

## 🗑️ Uninstallation

To cleanly remove Sys-Guardian from `/etc/` and `/usr/local/bin/`, run:

```bash
sudo ./uninstall.sh
```

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0](LICENSE) - see the LICENSE file for details.
