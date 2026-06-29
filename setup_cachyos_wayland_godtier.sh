#!/usr/bin/env bash

# ========================================================================
# Script Personalisasi & Optimasi "WAYLAND GOD-TIER" (HYPRLAND)
# Dibuat khusus: OS CachyOS x86_64 | DYNAMIC AUTO-DETECT (INTEL & AMD)
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
sudo pacman -Syu --noconfirm --needed \
    fish hyprland waybar swaybg rofi-wayland mako polkit-kde-agent \
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk wireplumber \
    ttf-jetbrains-mono-nerd papirus-icon-theme qterminal fastfetch scx-scheds ananicy-cpp \
    cachyos-ananicy-rules irqbalance auto-cpufreq pacman-contrib \
    network-manager-applet blueman bluez bluez-utils brightnessctl \
    fprintd pavucontrol qt5-wayland qt6-wayland

# Cek nwg-dock-hyprland (Khas CachyOS/AUR)
if pacman -Ss nwg-dock-hyprland >/dev/null; then
    sudo pacman -S --noconfirm --needed nwg-dock-hyprland || true
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
if ! grep -q "exec Hyprland" ~/.config/fish/config.fish 2>/dev/null; then
    cat << 'EOF' >> ~/.config/fish/config.fish

# Autostart Wayland (Hyprland) via TTY
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec Hyprland
    end
end
EOF
fi

# 4. Hyprland, Waybar & nwg-dock Config
echo ""
echo "[4/20] Menyiapkan Konfigurasi Inti Hyprland, Waybar & Dock..."
mkdir -p ~/.config/hypr
[ -f ~/.config/hypr/hyprland.conf ] && cp ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak || true
cat << 'EOF' > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,1

# Autostart Daemons & Integrasi Portal Wayland
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = swaybg -c "#282a36"
exec-once = waybar
exec-once = nm-applet --indicator & blueman-applet
exec-once = nwg-dock-hyprland -d -x -p bottom -l top

input {
    kb_layout = us
    touchpad {
        natural_scroll = true
        tap-to-click = true
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

# Media & Brightness Control (Wajib untuk Laptop)
bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
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
export QT_QPA_PLATFORM="wayland;xcb"
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
#!/usr/bin/env bash
if pacman -Qtdq > /dev/null 2>&1; then
    pacman -Rns $(pacman -Qtdq) --noconfirm || true
fi
pacman -Sc --noconfirm || true
paccache -rk2 || true
rm -rf /home/*/.cache/* || true
journalctl --vacuum-size=100M || true
sync
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
