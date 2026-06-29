# CachyOS Wayland God-Tier Setup (Hyprland Edition)

Script instalasi, personalisasi, dan optimasi komprehensif untuk OS CachyOS. Dirancang khusus bagi Anda yang ingin mencapai puncak performa (*absolute peak performance*) dengan meninggalkan protokol X11 yang usang dan beralih penuh ke ekosistem **Wayland Murni (Hyprland)**.

## Fitur Unggulan (Wayland God-Tier)

Script ini dirancang untuk menciptakan keseimbangan absolut antara performa latensi-nol, estetika premium, dan keamanan baterai laptop:

1. **Hyprland Murni & TTY Autologin (Zero RAM Login)**
   - Display Manager berat (seperti SDDM atau GDM) **dimatikan secara permanen**.
   - Laptop akan masuk secara otomatis (Autologin) via TTY hitam, dan langsung ditembak ke dalam sesi Hyprland menggunakan injeksi *Fish Shell*. Ini menghemat hingga 100MB RAM.

2. **Panel & Dock Modern (Tanpa Kompositor Tambahan)**
   - Menggunakan **Waybar** (panel cerdas pendeteksi WiFi/Baterai) dan **nwg-dock-hyprland** sebagai navigasi utama.
   - Skrip ini otomatis menambal *bug* "Blank Workspace" bawaan Waybar untuk memastikan Waybar dan Hyprland berkomunikasi sempurna.

3. **Hybrid Smart Power & Idle Security (Perlindungan Baterai)**
   - Diatur otomatis oleh `auto-cpufreq` (Turbo Auto saat di-*charge*, Powersave tanpa turbo saat pakai baterai).
   - Layar otomatis redup saat ditinggalkan, dan sistem akan mengunci (*lock*) secara agresif dengan **Hyprlock** & **Hypridle** sebelum laptop masuk ke mode tidur (suspend), mencegah kebocoran keamanan privasi saat di tempat umum.

4. **Integrasi Media & Wayland Portals (Anti-Freeze)**
   - Semua tombol *Media Keys* laptop (Brightness, Volume, Mute) dihidupkan paksa melalui *keybinds* Hyprland.
   - Menginjeksi **XDG Desktop Portals** dan daemon **DBus**. Dijamin tidak akan ada aplikasi Flatpak atau *Screen Sharing* (Discord/OBS) yang mogok atau layar nge- *freeze*.

5. **Proteksi UI (Keindahan yang Konsisten)**
   - Memaksa variabel khusus agar aplikasi Qt (seperti QTerminal) tidak menggambar bingkai ganda (*Double Titlebar Bug*).
   - Menyuntikkan tema standar `Arc-Dark` dan *icon* `Papirus` ke modul GTK, memastikan tidak ada aplikasi (seperti Pengaturan Suara) yang mundur ke tema putih Adwaita lawas.
   - Memperbaiki memori "Copy-Paste" (Clipboard) di Wayland menggunakan `wl-clipboard` agar teks tidak hilang saat aplikasi ditutup.

6. **Tuning Kernel & Gecko Engine Terpusat**
   - TCP BBRv3, *Transparent Huge Pages* (THP), *MGLRU*, I/O Scheduler SSD `kyber`, hingga latensi memori agresif.
   - Injeksi 25+ parameter kustom ke profil Firefox / Cachy-Browser bahkan jika browser belum pernah dibuka sama sekali (*headless generation*).

7. **Pembersih Sampah Otomatis (Absolute Shutdown Cleanup)**
   - Sebuah modul systemd khusus berjalan setiap kali Anda mematikan laptop, memastikan *cache* pacman, yatim piatu (*orphans*), dan jurnal lawas terhapus secara otomatis, diakhiri dengan *fstrim*.

## Peringatan Keras

- **Root-Blocker:** JANGAN PERNAH menjalankan skrip ini menggunakan `sudo bash`. Skrip ini memiliki sensor pendeteksi root dan akan mati otomatis. Skrip dirancang untuk dijalankan sebagai *user* biasa (akan meminta password `sudo` secara elegan di dalam terminal).
- Skrip ini diperuntukkan untuk **Fresh Install** CachyOS (atau sistem yang masih relatif baru) demi menghindari bentrokan konfigurasi ekstensif. Sistem auto-backup bawaan skrip ini (`.bak`) akan berusaha menyelamatkan konfigurasi lama Anda jika ditemukan.

## Panduan Eksekusi

Jalankan perintah berikut di dalam terminal Anda:

```bash
cd ~/Scripts/CACHYOS_SETUP
chmod +x setup_cachyos_wayland_godtier.sh
./setup_cachyos_wayland_godtier.sh
```

Setelah log terminal menyatakan instalasi berhasil (Tahap 20), silakan *Reboot* mesin Anda. Jangan panik jika Anda tidak melihat layar SDDM. Terminal TTY akan berkedip singkat, dan membawa Anda langsung ke Desktop Wayland masa depan.
