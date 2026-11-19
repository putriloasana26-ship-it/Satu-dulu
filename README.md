# Satu Dulu

## Menjalankan
1. `flutter create --platforms=android,windows .` di dalam folder ini (membuat folder android/ dan windows/; lib/ dan pubspec.yaml tidak ditimpa).
2. `flutter pub get`
3. Android: salin `android_native/MainActivity.kt` ke `android/app/src/main/kotlin/<package>/` (sesuaikan baris `package`), lalu tambahkan di `android/app/src/main/AndroidManifest.xml` (di atas `<application>`):
   `<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions"/>`
   (tambahkan `xmlns:tools="http://schemas.android.com/tools"` pada tag `<manifest>`).
4. `flutter run -d windows` atau `flutter run -d <perangkat android>`

## Cara kerja pembatasan
- Android: UsageStatsManager membaca aplikasi di layar; saat aplikasi terbatas terdeteksi, Satu Dulu ditarik kembali ke depan dan percobaan dicatat. Pengguna harus memberi izin Usage Access sekali.
- Windows: judul jendela aktif dibaca via Win32 (judul tab browser memuat nama website, mis. "YouTube"). Satu Dulu difokuskan kembali saat terdeteksi.
- Pencocokan memakai kata kunci (lihat daftar `apps` di `lib/main.dart`); tambah kata kunci game/website lain di sana atau lewat kolom "Tambah".

## Batasan
- Ini pembatasan berbasis deteksi + peringatan, bukan pemblokiran paksa. Pemblokiran penuh di Android butuh AccessibilityService/overlay, dan di Windows butuh pemblokiran proses atau hosts; keduanya bisa dijadikan pengembangan lanjutan.
- Android 10+ membatasi membuka aktivitas dari latar belakang; jika bringToFront tidak selalu berhasil, tambahkan izin "Display over other apps".
- Bunyi penanda selesai memakai bunyi sistem; ringtone khusus bisa ditambahkan dengan paket `audioplayers`, notifikasi dengan `flutter_local_notifications`.
