# Linux OS Kernel Setup & Optimization - by m4yestiK

A comprehensive, highly-optimized installation and personalization script for CachyOS. This script is engineered to bring your desktop to peak performance and aesthetics with a centralized setup architecture.

## 🚀 Features & Architecture

This repository contains the master setup script (`run.sh`) which provides a dynamic, interactive menu to configure your system into one of three distinct Desktop Environments (DE):

### 1. KDE Plasma (X11 Edition)
- Installs the full KDE Plasma suite optimized for X11.
- Injects custom `kdeglobals`, `kwinrc`, and `kcminputrc`.
- Bypasses SDDM directly using a TTY `startx` injection for a zero-RAM login sequence.

### 2. Hyprland (Wayland Edition)
- A pure Wayland ecosystem utilizing `hyprland`, `waybar`, and `mako`.
- Automatic Hyprland variable injections for QT (`QT_QPA_PLATFORM=wayland`) and GTK.
- Uses `hypridle` and `hyprlock` for modern power management and idle security.

### 3. LXQt Dracula (The Flagship Minimalist X11 Edition)
- An ultra-lightweight, visually stunning LXQt desktop powered by Openbox.
- **Polybar (Shapes/Cachy Theme):** Replaces the standard `lxqt-panel` (which is forcefully masked via `Hidden=true`) with a beautiful, dynamic top bar.
- **Plank Dock:** A transparent, macOS-like dock permanently anchored to the session using `env XDG_SESSION_TYPE=x11`.
- **Picom Compositor:** Injects transparency, shadows, and window animations into the rigid LXQt environment.
- **QTerminal Hardening:** Immersive borderless mode (`Borderless=true`), hidden menu bars, and deactivated blue active borders for a pure Dracula aesthetic.
- **Global GTK Styling:** Automatically enforces `Papirus-Dark` icons and `Arc-Dark` widgets across all GTK applications.

## 🛠️ Specialized Utilities

Alongside the master installer, this repository contains lethal, standalone scripts designed for deep system maintenance:

- **`deep_clean.sh` (Absolute SSD Cleanser)**
  A 100% safe, automated garbage collector. It aggressively clears Pacman orphan packages, sweeps systemd journals, annihilates unused Podman/Docker containers (`prune -a -f`), clears AUR caches, and triggers a comprehensive SSD Fstrim. Perfect for reclaiming gigabytes of disk space instantly.

- **`storage_radar.sh` (Storage Forensics)**
  A lightweight, real-time radar that probes the largest space hogs on your system. It instantly queries the exact Gigabyte consumption of your Virtual Machines (Libvirt), Podman layers (optimized via direct partition reads), Programming Projects, and Documents, displaying it in a color-coded terminal dashboard.

## ⚙️ Universal Optimizations (Applied to All DEs)

- **Pure TTY Autologin:** Completely abandons heavy Display Managers (SDDM/GDM) in favor of a raw `.xinitrc` or `.bash_profile` autologin, saving ~100MB of RAM.
- **Fingerprint (PAM) Integration:** Automatically injects `fprintd` into `system-local-login` for instant fingerprint authentication across the OS.
- **Firefox Telemetry Purge:** Injects `user.js` to forcefully disable Pocket, Telemetry, and unnecessary network requests.

## 📥 Execution Guide

Clone this repository and run the master script as a standard user (never as `root`, the script will ask for `sudo` internally):

```bash
cd ~/Dokumen/LAINNYA/scripts/CACHYOS_SETUP
chmod +x run.sh
./run.sh
```

Follow the interactive menu to select your desired Desktop Environment. After the script successfully completes (Stage 20), simply reboot your machine. 

Welcome to the absolute pinnacle of CachyOS.
