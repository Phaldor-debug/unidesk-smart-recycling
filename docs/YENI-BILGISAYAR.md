# Yeni Bilgisayarda Kuruluma Devam

Bu proje başka bir bilgisayara taşındığında sıfırdan çalışır hale getirmek için
izlenecek adımlar. Kurulum sırasında karşılaştığımız gerçek sorunlar ve çözümleri
de burada — aynı duvarlara tekrar toslamamak için.

---

## 1. Depoyu al

```powershell
git clone https://github.com/Phaldor-debug/unidesk-geri-donusum.git
cd unidesk-geri-donusum
```

Depo **private**. Yeni bilgisayarda GitHub erişimi için:

```powershell
winget install GitHub.cli
gh auth login
```

`GitHub.com` → `HTTPS` → `Yes` → `Login with a web browser` seç.
Tarayıcıda kodu yapıştırdıktan sonra **terminale dönüp Enter'a basmayı unutma** —
terminal orada bekliyor, basmazsan giriş tamamlanmıyor.

---

## 2. Araçları kur

Hepsi `winget` ile. Her kurulumdan sonra **terminali kapatıp yeniden aç**
(yeni programlar ancak yeni terminalde tanınır).

```powershell
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Google.AndroidStudio
```

### PowerShell script izni

Node kurulduktan sonra `npm` çalışmazsa:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Flutter

`winget`'te resmi paketi yok, elle kurulur:

```powershell
mkdir C:\src
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable
```

Sonra `C:\src\flutter\bin` yolunu **Path** değişkenine ekle.

> Dikkat: "Flutter" adında YENİ bir değişken oluşturma — mevcut `Path`
> değişkeninin İÇİNE eklenmeli. Bu hatayı bir kez yaptık.

### Android SDK bileşenleri

Android Studio'yu bir kez aç, Setup Wizard'da **Standard** seç.
Sonra **SDK Manager → SDK Tools** sekmesinden
**Android SDK Command-line Tools (latest)** kutusunu işaretle.

### Windows Geliştirici Modu

Flutter eklentileri sembolik link kullanıyor, açık olmalı:

```powershell
start ms-settings:developers
```

---

## 3. Bilinen kurulum sorunları

| Sorun | Sebep | Çözüm |
|---|---|---|
| `flutter doctor` "Android license status unknown" diyor | Yeni Android araçları `sdkmanager`'ı emekliye ayırdı, Flutter henüz uyumlu değil | Kozmetik, derlemeyi engellemiyor. Lisans dosyaları `%LOCALAPPDATA%\Android\Sdk\licenses` altına elle yazıldı |
| `flutter run` NDK hatası veriyor (NTSTATUS 0xC0000409) | Gradle, NDK'yı bozuk `sdkmanager` ile indirmeye çalışıyor | Elle kur: cmdline-tools/latest/bin altındaki `android.exe` ile `android sdk install ndk/28.2.13676358` |
| Telefon `adb devices` listesinde yok | USB modu "sadece şarj" | Telefonda bildirim çubuğundan **Dosya aktarımı (MTP)** seç. Sonra `adb kill-server` + `adb start-server` |
| Wokwi web arayüzü "Build Servers Busy" | Ücretsiz derleme kuyruğu yoğun | Bekleyip tekrar dene. Kodun derlendiğini yerelde doğrulamak için `arduino-cli` yeterli |

---

## 4. Firebase erişimi

Firebase tarafında **taşınacak bir şey yok** — her şey bulutta.
Yeni bilgisayarda sadece aynı Google hesabıyla giriş yap:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

`dart pub global activate` sonrası `%LOCALAPPDATA%\Pub\Cache\bin` yolunu da
**Path**'e ekle.

> `flutterfire configure` komutunu TEKRAR ÇALIŞTIRMA. `lib/firebase_options.dart`
> ve `android/app/google-services.json` zaten depoda; tekrar çalıştırmak
> gereksiz yere yeniden yapılandırır.

Projeye erişim: Firebase Console → `unidesk-geri-donusum`.
Ekibe başka biri katılacaksa Console → Project settings → Users and permissions
üzerinden davet edilir.

---

## 5. Projeyi çalıştır

```powershell
flutter pub get
flutter run -d chrome        # hızlı test
flutter run                  # telefon bağlıysa
```

Tarayıcıda kamera taraması bilerek kapalı — QR ekranında
**"Test kutusuyla devam et"** butonu çıkar.

---

## 6. Firmware (ESP32)

`firmware/unidesk_bin/` altında `unidesk_bin.ino` ve Wokwi devre şeması var.
Sanal test için [wokwi.com](https://wokwi.com) → New Project → ESP32,
iki dosyanın içeriğini yapıştır, `libraries.txt` içine:

```
Firebase Arduino Client Library for ESP8266 and ESP32
ESP32Servo
```

Kodun derlendiğini yerelde kontrol etmek için:

```powershell
winget install ArduinoSA.CLI
arduino-cli core install esp32:esp32
arduino-cli compile --fqbn esp32:esp32:esp32 firmware/unidesk_bin
```

---

## 7. Claude Code sohbetini taşımak (opsiyonel)

Konuşma geçmişi ve proje hafızası şurada tutuluyor:

```
C:\Users\<kullanıcı>\.claude\projects\c--Users-cengi-unidesk-geri-donusum\
```

Klasörün tamamını yeni bilgisayarda **aynı yola** kopyalarsan eski sohbetler
`claude --resume` ile açılabilir.

> Klasör adı, proje dizininin tam yolundan türetiliyor. Proje yeni bilgisayarda
> farklı bir yere konursa ad da değişir ve eşleşmez. En kolayı aynı yolu kullanmak:
> `C:\Users\<kullanıcı>\unidesk_geri_donusum`

Kopyalamasan da sorun olmaz: bu dosya ve `memory/` klasöründeki notlar projenin
durumunu ve alınan kararları zaten anlatıyor.

---

## 8. Projenin mevcut durumu

**Çalışıyor:** kayıt/giriş, e-posta doğrulama, atık atma akışı (QR + simülatör),
puan cüzdanı ve geçmişi, ödül kodları, yemekhane doğrulaması, aylık sıralama,
profil ekranı, Firestore güvenlik kuralları, ESP32 köprüsü, firmware taslağı.

**Yapılmadı:** sunucu tarafı puan doğrulama (Cloud Functions), rol sistemi ve
yönetici paneli, KVKK metinleri, mağaza yayını, bildirimler, dinamik QR,
gerçek donanım montajı.

**Bilinçli kapalı bırakılanlar:**
- Öğrenci e-posta kısıtı (`AppConstants.izinliEpostaUzantilari` boş).
  Açmak için: `<String>['ogr.alanya.edu.tr']`
- Kutu QR'ı sabit; dinamik QR donanım ekranı geldiğinde eklenecek
