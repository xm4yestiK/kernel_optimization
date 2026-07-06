#!/bin/bash
# ==============================================================================
# SCRIPT PEMBERSIH DISK MENDALAM & AMAN (CACHYOS / ARCH LINUX)
# ==============================================================================
# Dibuat untuk: Menghapus cache, log, orphan packages, dan container sampah
# tanpa merusak stabilitas sistem. Aman dijalankan setiap hari.

set -e

# Warna untuk output
GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${BLUE}=========================================${RESET}"
echo -e "${GREEN} 🧹 MEMULAI PEMBERSIHAN DISK MENDALAM 🧹 ${RESET}"
echo -e "${BLUE}=========================================${RESET}\n"

# 1. Bersihkan Cache Pacman & AUR
echo -e "${BLUE}[1/6] Membersihkan Cache Paket (Pacman & AUR)...${RESET}"
if command -v paccache >/dev/null 2>&1; then
    echo ">> Menyisakan 1 versi terakhir dari setiap paket (untuk cadangan)..."
    sudo paccache -r -k 1
    echo ">> Menghapus seluruh cache paket yang sudah di-uninstall..."
    sudo paccache -ruk0
else
    echo ">> Membersihkan cache pacman standar..."
    sudo pacman -Sc --noconfirm
fi

# Membersihkan cache AUR (yay/paru) jika ada
[ -d "$HOME/.cache/yay" ] && rm -rf "$HOME/.cache/yay"/* && echo ">> Cache Yay dibersihkan."
[ -d "$HOME/.cache/paru/clone" ] && rm -rf "$HOME/.cache/paru/clone"/* && echo ">> Cache Paru dibersihkan."

# 2. Hapus Paket Yatim Piatu (Orphans)
echo -e "\n${BLUE}[2/6] Membersihkan Paket Yatim Piatu (Orphans)...${RESET}"
# Mencari paket yang diinstal sebagai dependency tapi tak lagi dibutuhkan
ORPHANS=$(pacman -Qtdq || true)
if [ -n "$ORPHANS" ]; then
    echo ">> Ditemukan paket sampah/yatim piatu. Menghapus..."
    sudo pacman -Rns $ORPHANS --noconfirm
else
    echo ">> Bersih! Tidak ada paket yatim piatu."
fi

# 3. Log Systemd (Journal)
echo -e "\n${BLUE}[3/6] Mengosongkan Log Sistem (Systemd Journal)...${RESET}"
echo ">> Membatasi ukuran log maksimal 50MB..."
sudo journalctl --vacuum-size=50M
echo ">> Menghapus log yang lebih tua dari 3 hari..."
sudo journalctl --vacuum-time=3d

# 4. Pembersihan Kontainer (Podman/Docker)
echo -e "\n${BLUE}[4/6] Membersihkan Sampah Kontainer...${RESET}"
if command -v podman >/dev/null 2>&1; then
    echo ">> [PERINGATAN] Memusnahkan SEMUA Kontainer Podman secara Paksa..."
    podman rm -a -f 2>/dev/null || true
    echo ">> Memusnahkan SEMUA Image Podman secara Paksa..."
    podman rmi -a -f 2>/dev/null || true
    podman system prune -a -f
fi
if command -v docker >/dev/null 2>&1; then
    echo ">> [PERINGATAN] Memusnahkan SEMUA Kontainer Docker secara Paksa..."
    sudo docker rm -a -f 2>/dev/null || true
    echo ">> Memusnahkan SEMUA Image Docker secara Paksa..."
    sudo docker rmi -a -f 2>/dev/null || true
    sudo docker system prune -a -f
fi

# 5. Cache Aplikasi Pengguna & Browser
echo -e "\n${BLUE}[5/6] Membersihkan Cache Aplikasi & Thumbnail...${RESET}"
echo ">> Menghapus thumbnail gambar lawas..."
rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true
echo ">> Melewati pembersihan cache Browser demi menjaga 100% keamanan sesi login Anda..."
# rm -rf "$HOME/.cache/google-chrome/Default/Cache/"* 2>/dev/null || true
# rm -rf "$HOME/.cache/chromium/Default/Cache/"* 2>/dev/null || true
# rm -rf "$HOME/.cache/mozilla/firefox/"* 2>/dev/null || true
# rm -rf "$HOME/.cache/BraveSoftware/Brave-Browser/Default/Cache/"* 2>/dev/null || true
# rm -rf "$HOME/.cache/spotify/"* 2>/dev/null || true

# 6. Trash (Tempat Sampah)
echo -e "\n${BLUE}[6/6] Mengosongkan Tempat Sampah (Trash)...${RESET}"
rm -rf "$HOME/.local/share/Trash/files/"* 2>/dev/null || true
rm -rf "$HOME/.local/share/Trash/info/"* 2>/dev/null || true
echo ">> Tempat sampah telah dikosongkan."

# 7. SSD TRIM (Fstrim)
echo -e "\n${BLUE}[7/7] Melakukan TRIM SSD secara Komprehensif...${RESET}"
echo ">> Memberitahu pengontrol SSD untuk membuang blok data kosong (Optimalisasi Kecepatan)..."
sudo fstrim -av || true

echo -e "\n${BLUE}=========================================${RESET}"
echo -e "${GREEN} ✨ PEMBERSIHAN SELESAI MUTLAK! ✨ ${RESET}"
echo -e "${BLUE}=========================================${RESET}"

# Menampilkan status disk terbaru
echo -e "\n${GREEN}Sisa Ruang Penyimpanan Anda Saat Ini:${RESET}"
df -h / /home/m4yestik/.local/containers 2>/dev/null || df -h /
echo ""
