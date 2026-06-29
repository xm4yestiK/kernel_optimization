#!/usr/bin/env bash

# ========================================================================
# Script Personalisasi & Optimasi "WAYLAND GOD-TIER" (HYPRLAND)
# Dibuat khusus: OS CachyOS x86_64 | DYNAMIC AUTO-DETECT (INTEL & AMD)
#
# PANDUAN INSTALASI CACHYOS (Calamares):
# 1. Pilih opsi "No Desktop Environment" (CLI) jika tersedia.
# 2. Jika wajib memilih DE, pilih "Hyprland" atau "Sway".
# 3. JANGAN PERNAH memilih LXQt, XFCE, atau Openbox (X11 Bloat).
# 
# [FITUR UTAMA SCRIPT INI]:
# - Migrasi total dari X11 (Openbox) ke WAYLAND murni (Hyprland).
# - Tanpa SDDM (TTY Autologin langsung tembus ke Hyprland).
# - Waybar + nwg-dock sebagai panel & dock modern tanpa komposisi pihak ketiga.
# - Proteksi Root, Auto-backup, Hardware Intelijen, Gecko Tuning, Smart-power.
# ========================================================================

set -e

if [ "$EUID" -eq 0 ]; then
  echo "================================================================="
  echo "[-] FATAL ERROR: JANGAN JALANKAN SCRIPT INI DENGAN 'SUDO' ATAU ROOT!"
  echo "    Script ini dirancang untuk dijalankan sebagai User Biasa."
  echo "    Silakan jalankan ulang tanpa 'sudo'."
  echo "================================================================="
  exit 1
fi

USER_NAME=$(whoami)

echo "================================================================="
echo "Memulai injeksi performa WAYLAND GOD-TIER CachyOS (Juni 2026)..."
echo "================================================================="

# ========================================================================
# AUTO-DETEKSI HARDWARE (CPU & GPU)
# ========================================================================
echo ">> [PROSES] Mendeteksi Vendor CPU..."
CPU_VENDOR=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
GPU_VENDOR="unknown"

echo ">> [PROSES] Mendeteksi Vendor GPU (VGA/3D)..."
if lspci -nn | grep -i 'vga\|3d\|display' | grep -iq 'intel'; then
    GPU_VENDOR="intel"
elif lspci -nn | grep -i 'vga\|3d\|display' | grep -iq 'amd\|radeon'; then
    GPU_VENDOR="amd"
fi

echo ">> HASIL DETEKSI CPU: $CPU_VENDOR"
echo ">> HASIL DETEKSI GPU: $GPU_VENDOR"
echo "================================================================="

# 1. Update & Instalasi Wayland Stack
echo ""
echo "[1/20] Instalasi Ekosistem Wayland + Paket Tuning..."
# Mengamankan PGP Keyring dari kegagalan sinkronisasi fresh install
sudo pacman -Sy --noconfirm archlinux-keyring cachyos-keyring || true
sudo pacman -Syu --noconfirm --needed \
    fish hyprland waybar swaybg rofi-wayland mako hyprpolkitagent \
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk wireplumber pipewire-pulse pipewire-alsa pipewire-jack \
    ttf-jetbrains-mono-nerd ttf-font-awesome papirus-icon-theme arc-gtk-theme kvantum qterminal fastfetch scx-scheds \
    ananicy-cpp cachyos-ananicy-rules irqbalance auto-cpufreq pacman-contrib \
    network-manager-applet blueman bluez bluez-utils brightnessctl \
    fprintd pavucontrol qt5-wayland qt6-wayland hyprlock hypridle wl-clipboard cliphist grim slurp xdg-user-dirs

# Mengamankan Struktur Direktori dan Font Cache
xdg-user-dirs-update || true
fc-cache -fv >/dev/null 2>&1 || true

# Cek nwg-dock-hyprland (Khas CachyOS/AUR Fallback)
if pacman -Ss nwg-dock-hyprland >/dev/null; then
    sudo pacman -S --noconfirm --needed nwg-dock-hyprland || true
elif command -v paru >/dev/null; then
    paru -S --noconfirm --needed nwg-dock-hyprland || true
elif command -v yay >/dev/null; then
    yay -S --noconfirm --needed nwg-dock-hyprland || true
else
    sudo pacman -S --noconfirm --needed nwg-dock || true
fi

# 2. Setup Shell & Locale
echo ""
echo "[2/20] Setup Shell & Locale..."
[ "$SHELL" != "/usr/bin/fish" ] && chsh -s /usr/bin/fish || true
sudo sed -i 's/^#id_ID.UTF-8 UTF-8/id_ID.UTF-8 UTF-8/' /etc/locale.gen || true
sudo locale-gen >/dev/null 2>&1 || true
sudo localectl set-locale LANG=id_ID.UTF-8 || true

# 3. TTY Autologin (Membunuh SDDM)
echo ""
echo "[3/20] Meruntuhkan SDDM & Membangun TTY Autologin..."
sudo systemctl disable display-manager.service --force 2>/dev/null || true
sudo systemctl disable sddm.service 2>/dev/null || true
sudo systemctl disable lightdm.service 2>/dev/null || true
sudo systemctl disable gdm.service 2>/dev/null || true

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

mkdir -p ~/.config/fish
# Menambahkan trigger Hyprland otomatis saat TTY1 login
if ! grep -q "Hyprland" ~/.config/fish/config.fish 2>/dev/null; then
    cat << 'EOF' >> ~/.config/fish/config.fish

# Autostart Wayland (Hyprland) via TTY
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        # Menghapus 'exec' agar user memiliki fallback aman (ke terminal) jika Hyprland crash!
        Hyprland
    end
else if status is-interactive
    fastfetch
end
end
EOF
fi

# 4. Hyprland, Waybar & nwg-dock Config
echo ""
echo "[4/20] Menyiapkan Konfigurasi Inti Hyprland, Waybar & Dock..."
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/rofi

# Injeksi Waybar Config (Mencegah Blank Workspaces karena default Sway)
[ -f ~/.config/waybar/config ] && cp ~/.config/waybar/config ~/.config/waybar/config.bak || true
cat << 'EOF' > ~/.config/waybar/config
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "network", "pulseaudio", "battery"],
    "hyprland/workspaces": { "format": "{icon}", "on-click": "activate" },
    "clock": { "format": "{:%H:%M - %d %b}" },
    "network": { "format-wifi": "  {essid}", "format-ethernet": "  {ipaddr}", "format-disconnected": "⚠ Disconnected" },
    "battery": { "states": { "warning": 30, "critical": 15 }, "format": "{icon}  {capacity}%", "format-icons": ["", "", "", "", ""] },
    "pulseaudio": { "format": "{icon}  {volume}%", "format-muted": " Muted", "format-icons": { "default": ["", "", ""] } }
}
EOF

# Injeksi Rofi Config (Mencegah GUI jelek)
[ -f ~/.config/rofi/config.rasi ] && cp ~/.config/rofi/config.rasi ~/.config/rofi/config.rasi.bak || true
cat << 'EOF' > ~/.config/rofi/config.rasi
configuration {
    modi: "drun,run";
    show-icons: true;
    font: "JetBrainsMono Nerd Font 12";
}
/* Hapus @theme Arc-Dark karena rawan crash jika tema tidak terinstal */
EOF

mkdir -p ~/.config/hypr
# Pembersihan Blok Hyprpaper (Reverted ke Swaybg)

[ -f ~/.config/hypr/hyprland.conf ] && cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak || true
cat << 'EOF' > ~/.config/hypr/hyprland.conf
# Auto-scale monitor cerdas (mencegah GUI hancur di monitor 4K/HiDPI)
monitor=,preferred,auto,auto

# Mengunci Ukuran Kursor (Mencegah Bug Kursor Raksasa/Kecil di Wayland)
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita

# Autostart Daemons & Integrasi Portal Wayland
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
# Menggunakan agen polkit native Hyprland standar 2026
exec-once = systemd-cat -t hyprpolkitagent /usr/lib/hyprpolkitagent
exec-once = swaybg -c "#282a36"
exec-once = waybar
# Pemisahan proses background untuk mencegah zombie process di Hyprland
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = nwg-dock-hyprland -d -x -p bottom -l top
exec-once = hypridle
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

input {
    kb_layout = us
    touchpad {
        natural_scroll = true
        tap-to-click = true
        disable_while_typing = true
    }
}
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(bd93f9ee) rgba(ff79c6ee) 45deg
    layout = dwindle
}
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}
animations {
    enabled = yes
}
bind = SUPER, Return, exec, qterminal
bind = SUPER, Q, killactive, 
bind = SUPER, M, exit, 
bind = SUPER, V, togglefloating, 
bind = SUPER, R, exec, rofi -show drun
# Manajemen Jendela dan Workspace (Sangat Vital)
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4

# Media & Brightness Control (Wajib untuk Laptop)
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Screenshot (Wajib untuk Wayland)
bind = , Print, exec, grim -g "\$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy
EOF

echo ""
echo "[4.5/20] Menyiapkan Sistem Keamanan Layar & Kustomisasi GTK Wayland..."
# Hypridle Config
[ -f ~/.config/hypr/hypridle.conf ] && cp ~/.config/hypr/hypridle.conf ~/.config/hypr/hypridle.conf.bak || true
cat << 'EOF' > ~/.config/hypr/hypridle.conf
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}
listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF

# Hyprlock Config
[ -f ~/.config/hypr/hyprlock.conf ] && cp ~/.config/hypr/hyprlock.conf ~/.config/hypr/hyprlock.conf.bak || true
cat << 'EOF' > ~/.config/hypr/hyprlock.conf
background {
    monitor =
    color = rgba(40, 42, 54, 1.0)
}
input-field {
    monitor =
    size = 250, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    outer_color = rgb(189, 147, 249)
    inner_color = rgb(40, 42, 54)
    font_color = rgb(248, 248, 242)
    fade_on_empty = true
    placeholder_text = <i>Password...</i>
    hide_input = false
    position = 0, -20
    halign = center
    valign = center
}
label {
    monitor =
    text = $TIME
    color = rgba(248, 248, 242, 1.0)
    font_size = 50
    font_family = JetBrainsMonoNL Nerd Font
    position = 0, 80
    halign = center
    valign = center
}
EOF

# Menyelamatkan Tema GTK dari keburukan default Adwaita
mkdir -p ~/.config/gtk-3.0
cat << 'EOF' > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF

# Menyelamatkan Tema QT dengan Kvantum Arc-Dark
mkdir -p ~/.config/Kvantum
cat << 'EOF' > ~/.config/Kvantum/kvantum.kvconfig
[General]
theme=KvArcDark#
EOF

# 5. QTerminal Dracula Purple
echo ""
echo "[5/20] Menginjeksi Skema Warna Dracula Purple untuk QTerminal..."
sudo mkdir -p /usr/share/qtermwidget5/color-schemes/ /usr/share/qtermwidget6/color-schemes/
sudo tee /usr/share/qtermwidget5/color-schemes/DraculaPurple.colorscheme /usr/share/qtermwidget6/color-schemes/DraculaPurple.colorscheme > /dev/null << 'EOF'
[General]
Description=Dracula Purple per 2026
Opacity=1
[Background]
Color=40,42,54
[Foreground]
Color=248,248,242
[Color0]
Color=40,42,54
[Color0Intense]
Color=98,114,164
[Color1]
Color=255,85,85
[Color1Intense]
Color=255,106,106
[Color2]
Color=80,250,123
[Color2Intense]
Color=96,253,143
[Color3]
Color=241,250,140
[Color3Intense]
Color=242,251,160
[Color4]
Color=189,147,249
[Color4Intense]
Color=202,169,250
[Color5]
Color=255,121,198
[Color5Intense]
Color=255,146,211
[Color6]
Color=139,233,253
[Color6Intense]
Color=154,237,254
[Color7]
Color=248,248,242
[Color7Intense]
Color=255,255,255
EOF
mkdir -p ~/.config/qterminal.org
[ -f ~/.config/qterminal.org/qterminal.ini ] && cp ~/.config/qterminal.org/qterminal.ini ~/.config/qterminal.org/qterminal.ini.bak || true
cat <<EOF > ~/.config/qterminal.org/qterminal.ini
[General]
fontFamily=JetBrainsMonoNL Nerd Font Mono
fontSize=14
colorScheme=DraculaPurple
EOF

# 6. Integrasi Fingerprint (PAM)
echo ""
echo "[6/20] Mendaftarkan Fingerprint (fprintd) ke modul PAM TTY..."
if [ -f /etc/pam.d/system-local-login ] && ! grep -q "pam_fprintd.so" /etc/pam.d/system-local-login; then
    sudo sed -i '1iauth      sufficient  pam_fprintd.so' /etc/pam.d/system-local-login || true
fi

# 7. Integrasi Optimasi Firefox
echo ""
echo "[7/20] Menyuntikkan Tuning Mentok Engine Gecko..."
killall -9 firefox cachy-browser 2>/dev/null || true
sleep 0.5
command -v firefox >/dev/null && firefox --headless -CreateProfile "default" 2>/dev/null || true
command -v cachy-browser >/dev/null && cachy-browser --headless -CreateProfile "default" 2>/dev/null || true
for PROFILE_DIR in ~/.mozilla/firefox/*.default* ~/.cachy/cachy-browser/*.default* ~/.config/mozilla/firefox/*.default*; do
    if [ -d "$PROFILE_DIR" ]; then
        [ -f "$PROFILE_DIR/user.js" ] && cp "$PROFILE_DIR/user.js" "$PROFILE_DIR/user.js.bak" || true
        cat << 'EOF' > "$PROFILE_DIR/user.js"
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("gfx.canvas.accelerated", true);
user_pref("network.http.http3.enable", true);
user_pref("network.http.max-connections", 1800);
EOF
    fi
done

# 8. Kernel Sysctl
echo ""
echo "[8/20] Kernel Sysctl (Latensi Nol & TCP BBRv3)..."
sudo mkdir -p /etc/sysctl.d
cat <<EOF | sudo tee /etc/sysctl.d/99-cachyos-godtier.conf
vm.swappiness=150
vm.page-cluster=0
vm.watermark_boost_factor=20000
vm.watermark_scale_factor=250
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_low_latency=1
kernel.split_lock_mitigate=0
EOF
sudo sysctl --system || true

# 9. MGLRU & THP
echo ""
echo "[9/20] Mengaktifkan MGLRU & THP secara paksa..."
sudo mkdir -p /etc/tmpfiles.d
cat <<EOF | sudo tee /etc/tmpfiles.d/mglru-thp.conf
w /sys/kernel/mm/lru_gen/enabled - - - - 1
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
EOF

# 10. AUTO-CPUFREQ
echo ""
echo "[10/20] AUTO-CPUFREQ: Otak Manajemen Daya Cerdas..."
sudo mkdir -p /etc
cat <<EOF | sudo tee /etc/auto-cpufreq.conf
[battery]
governor = powersave
energy_performance_preference = power
turbo = never
[charger]
governor = performance
energy_performance_preference = performance
turbo = auto
EOF

# 11. Driver iGPU
echo ""
echo "[11/20] Eksekusi Driver iGPU..."
sudo mkdir -p /etc/modprobe.d
if [ "$GPU_VENDOR" = "intel" ]; then
    cat <<EOF | sudo tee /etc/modprobe.d/gpu-godtier.conf
options i915 enable_guc=3 enable_fbc=1 enable_psr=1
EOF
elif [ "$GPU_VENDOR" = "amd" ]; then
    cat <<EOF | sudo tee /etc/modprobe.d/gpu-godtier.conf
options amdgpu ppfeaturemask=0xffffffff
EOF
fi

# 12. Environment Variables Wayland
echo ""
echo "[12/20] Menyuntikkan Variabel Lingkungan Khusus Wayland..."
sudo mkdir -p /etc/profile.d
cat <<EOF | sudo tee /etc/profile.d/wayland-godtier.sh
export MESA_NO_ERROR=1
export MOZ_ENABLE_WAYLAND=1
export LIBVA_DRIVER_NAME=iHD
export ELECTRON_OZONE_PLATFORM_HINT=auto
export MOZ_USE_XINPUT2=1
export QT_QPA_PLATFORM="wayland;xcb"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_STYLE_OVERRIDE=kvantum
export QT_QPA_PLATFORMTHEME=kvantum
export XCURSOR_SIZE=24
export XCURSOR_THEME=Adwaita
export GDK_BACKEND="wayland,x11"
export SDL_VIDEODRIVER="wayland,x11"
export XDG_SESSION_TYPE=wayland
EOF

# 13. Optimasi FSTAB
echo ""
echo "[13/20] Optimasi FSTAB..."
if [ -f /etc/fstab ]; then
    sudo cp /etc/fstab /etc/fstab.godtier.backup || true
    sudo sed -i 's/relatime/noatime,commit=60/g' /etc/fstab || true
fi

# 14. UDEV Rules SSD
echo ""
echo "[14/20] UDEV Rules: I/O Scheduler SSD/NVMe -> 'kyber'..."
sudo mkdir -p /etc/udev/rules.d
cat <<EOF | sudo tee /etc/udev/rules.d/60-ioschedulers.rules
ACTION=="add|change", KERNEL=="nvme[0-9]*|sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
EOF

# 15. Modul Absolute Shutdown Cleanup
echo ""
echo "[15/20] Membangun Modul Shutdown Cleanup..."
sudo mkdir -p /usr/local/bin
cat <<'EOF' | sudo tee /usr/local/bin/shutdown-cleanup.sh
#!/bin/bash
# Hapus cache pacman (sisakan 2 versi terakhir)
paccache -r -k2 || true
# Hapus cache AUR (Yay/Paru) yang menumpuk gila-gilaan
rm -rf /home/*/.cache/yay/* /home/*/.cache/paru/* 2>/dev/null || true
# Hapus paket yatim piatu (orphans)
pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || true
# Bersihkan log systemd yang lebih tua dari 3 hari
journalctl --vacuum-time=3d || true
# Eksekusi TRIM pada SSD
fstrim -av || true
EOF
sudo chmod +x /usr/local/bin/shutdown-cleanup.sh

cat <<EOF | sudo tee /etc/systemd/system/shutdown-cleanup.service
[Unit]
Description=Absolute SSD Purge and Clean on Shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target
Requires=local-fs.target
ConditionPathExists=/usr/local/bin/shutdown-cleanup.sh
[Service]
Type=oneshot
ExecStart=/usr/local/bin/shutdown-cleanup.sh
TimeoutSec=120
[Install]
WantedBy=halt.target shutdown.target
EOF

# 16. Parameter Boot Kritis
echo ""
echo "[16/20] Injeksi Parameter Boot Kritis (mitigations=off)..."
if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    BOOT_PARAMS="mitigations=off nowatchdog amd_pstate=active quiet"
else
    BOOT_PARAMS="mitigations=off nowatchdog quiet"
fi

if bootctl is-installed &>/dev/null; then
    shopt -s nullglob
    for entry in /boot/loader/entries/*.conf; do
        [ -f "$entry" ] || continue
        if ! grep -q "mitigations=off" "$entry"; then
            sudo sed -i "s/^\(options[[:space:]].*\)/\1 $BOOT_PARAMS/" "$entry"
        fi
    done
    shopt -u nullglob
elif [ -f /etc/kernel/cmdline ]; then
    if ! grep -q "mitigations=off" /etc/kernel/cmdline; then
        sudo sed -i "s/$/ $BOOT_PARAMS/" /etc/kernel/cmdline
        sudo sdboot-manage gen || sudo bootctl update || true
    fi
elif [ -f /etc/default/grub ]; then
    if ! grep -q "mitigations=off" /etc/default/grub; then
        sudo sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=[\"']\)/\1$BOOT_PARAMS /" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg || true
    fi
fi

# 17. Eksekusi Daemon
echo ""
echo "[17/20] Eksekusi Daemon & Pemusnahan Konflik Daya..."
sudo systemctl daemon-reload
sudo systemctl disable --now power-profiles-daemon.service tlp.service 2>/dev/null || true
sudo systemctl mask power-profiles-daemon.service tlp.service 2>/dev/null || true
sudo systemctl disable --now cpupower.service 2>/dev/null || true

sudo systemctl enable --now ananicy-cpp.service || true
sudo systemctl enable --now irqbalance.service || true
sudo systemctl enable --now auto-cpufreq.service || true
sudo systemctl enable shutdown-cleanup.service || true
sudo systemctl enable systemd-tmpfiles-setup.service || true
sudo systemctl enable --now bluetooth.service || true
sudo sed -i 's/^#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf || true
sudo sed -i 's/^#AutoEnable=true/AutoEnable=true/' /etc/bluetooth/main.conf || true
sudo timedatectl set-ntp true || true

if [ -f /etc/default/scx ]; then
    sudo sed -i 's/^SCX_SCHEDULER=.*/SCX_SCHEDULER="scx_lavd"/' /etc/default/scx
else
    sudo mkdir -p /etc/default
    echo 'SCX_SCHEDULER="scx_lavd"' | sudo tee /etc/default/scx
fi
sudo systemctl enable --now scx.service || true

# 18. Membangun Ulang Initramfs
echo ""
echo "[18/20] Membangun Ulang Initramfs (Universal)..."
if command -v mkinitcpio &> /dev/null; then
    sudo mkinitcpio -P || true
fi
if command -v dracut &> /dev/null; then
    sudo dracut --force --regenerate-all || true
fi

echo ""
echo "=============================================================================="
echo "[V] TRANSAKSI KE WAYLAND (HYPRLAND) SELESAI SEMPURNA!"
echo "SDDM telah dimatikan. Saat Anda reboot, mesin akan login otomatis di TTY1"
echo "dan langsung menembus ke Hyprland + Waybar + nwg-dock tanpa GUI Login."
echo "Silakan REBOOT perangkat Anda sekarang."
echo "=============================================================================="
