# EduFlex Draw

Aplikasi WPF .NET Framework 4.7.2 untuk menggambar di atas layar. Publisher aplikasi:
**CORTEX IMAGI NUSA**.

## Instal dari CMD tanpa login GitHub

Di Windows 10/11, buka CMD biasa (tidak perlu administrator) dan jalankan:

```cmd
curl.exe -fL "https://raw.githubusercontent.com/MJunJunJun/EduFlex-Draw-Download/main/Install.ps1" -o "%TEMP%\EduFlex-Install.ps1" && powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\EduFlex-Install.ps1"
```

Masukkan password instal yang dibagikan pemilik aplikasi. Input disamarkan.
Script mengunduh paket terenkripsi, memeriksa integritas dan checksum installer,
lalu membuka wizard instalasi. Tidak perlu akun GitHub, Git, atau GitHub CLI.
Aplikasi tidak meminta password saat dibuka.

Source tetap di repo private. Repo publik `MJunJunJun/EduFlex-Draw-Download`
hanya berisi script dan installer terenkripsi (AES-256-CBC, HMAC-SHA256,
PBKDF2 dengan 200.000 iterasi). Password dan token GitHub tidak dipublikasikan.
Paket dapat diunduh siapa saja, tetapi membutuhkan password untuk dibuka.
Installer yang sudah didekripsi tetap bisa disalin oleh pemegang password.

Untuk membuat ulang paket, jalankan `tools/installer/Build-PasswordPackage.ps1`.
Password disimpan menggunakan Windows DPAPI di `%LOCALAPPDATA%/EduFlexDraw/Deployment`,
di luar repo. Pertahankan versi dan checksum yang sesuai saat menerbitkan pembaruan.
Uji enkripsi: `powershell.exe -NoProfile -File tests/PasswordPackageTests.ps1`.

