#!/bin/bash
# ==============================================================================
# RADAR PENYIMPANAN MUTLAK
# ==============================================================================
# Mengecek secara real-time "Sarang Penyamun" (pemakan ruang raksasa) di sistem.

GREEN="\033[1;32m"
BLUE="\033[1;34m"
RED="\033[1;31m"
YLW="\033[1;33m"
RESET="\033[0m"

echo -e "${BLUE}=========================================${RESET}"
echo -e "${GREEN} 🛰️  MEMULAI PEMINDAIAN RADAR PENYIMPANAN 🛰️ ${RESET}"
echo -e "${BLUE}=========================================${RESET}\n"

# Fungsi pembantu untuk mengukur folder secara akurat
get_size() {
    local path=$1
    if [ -d "$path" ]; then
        # Jika butuh akses root (seperti libvirt)
        if [[ "$path" == "/var/lib/libvirt" ]]; then
            sudo du -sh "$path" 2>/dev/null | cut -f1
        else
            du -sh "$path" 2>/dev/null | cut -f1
        fi
    else
        echo "0"
    fi
}

echo -e "${YLW}Memindai aset dan parasit di dalam SSD Anda... Mohon tunggu beberapa detik...${RESET}\n"

# 1. KVM / QEMU
SIZE_VM=$(get_size "/var/lib/libvirt")
echo -e "${RED}1. Mesin Virtual (KVM/QEMU) - [${SIZE_VM}]${RESET}"
echo -e "   Lokasi: ${BLUE}/var/lib/libvirt${RESET}"
echo -e "   -> Mengandung File virtual disk (contoh: .qcow2 / .img) dari OS lain.\n"

# 2. Kontainer & Data Lokal (Dioptimalkan menggunakan pembacaan Partisi Langsung)
if findmnt "/home/m4yestiK/.local/containers" >/dev/null; then
    SIZE_LOCAL=$(df -h "/home/m4yestiK/.local/containers" | awk 'NR==2 {print $3}')
else
    SIZE_LOCAL=$(get_size "/home/m4yestik/.local")
fi
echo -e "${RED}2. Kontainer & Data Lokal - [${SIZE_LOCAL}]${RESET}"
echo -e "   Lokasi: ${BLUE}/home/m4yestik/.local${RESET}"
echo -e "   -> Mengandung Data Volume Database Podman/Docker, Flatpak, dan Lingkungan Python.\n"

# 3. Proyek Pemrograman
SIZE_PROYEK=$(get_size "/home/m4yestik/Proyek")
SIZE_GO=$(get_size "/home/m4yestik/go")
echo -e "${RED}3. Proyek Pemrograman - [${SIZE_PROYEK}] ${RESET}(Dependensi Golang: ${YLW}[${SIZE_GO}]${RESET})"
echo -e "   Lokasi: ${BLUE}/home/m4yestik/Proyek${RESET} & ${BLUE}/home/m4yestik/go${RESET}"
echo -e "   -> Mengandung node_modules, build cache, dan ribuan baris kode pribadi Anda.\n"

# 4. Dokumen Pribadi
SIZE_DOKUMEN=$(get_size "/home/m4yestik/Dokumen")
echo -e "${RED}4. Dokumen Pribadi - [${SIZE_DOKUMEN}]${RESET}"
echo -e "   Lokasi: ${BLUE}/home/m4yestik/Dokumen${RESET}"
echo -e "   -> Mengandung file-file media, unduhan, dan catatan Anda.\n"

echo -e "${BLUE}=========================================${RESET}"
echo -e "${GREEN} 📊 LAPORAN AKHIR PARTISI ROOT (/) 📊 ${RESET}"
df -h / | awk 'NR==2 {print "Total Kapasitas : " $2 "\nSedang Terpakai : " $3 " (" $5 ")\nRuang Tersisa   : " $4}'
echo -e "${BLUE}=========================================${RESET}"
