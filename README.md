# Ünidesk — Akıllı Geri Dönüşüm Kutusu

Üç bölmeli (Plastik / Kağıt / Cam) bir geri dönüşüm kutusu ve ona eşlik eden mobil
uygulama. Öğrenci uygulamadan atık türünü seçer, kutunun QR kodunu okutur; kutu
yalnızca ilgili bölmenin kapağını açar, kızılötesi sensörle atılan adedi sayar ve
öğrenciye puan yazar. Biriken puanlar uygulamada üretilen tek kullanımlık bir kodla
yemekhanede ücretsiz yemek gibi haklara dönüştürülür.

## Sistem mimarisi

```
┌──────────────┐   Firestore    ┌──────────────┐   Realtime DB   ┌──────────┐
│   Flutter    │◄──────────────►│   Firebase   │◄───────────────►│  ESP32   │
│  (Android)   │  kullanıcı,    │              │  kapak komutu,  │ 3 servo  │
│              │  puan, ödül    │              │  atık sayacı    │ 3 IR sns │
└──────────────┘                └──────────────┘                 └──────────┘
```

- **Firestore** — kalıcı kayıtlar: kullanıcılar, puanlar, oturumlar, ödüller, kodlar
- **Realtime Database** — ESP32 ile canlı haberleşme kanalı (`/bin_commands/{binId}`).
  Bilinçli tercih: RTDB'nin ESP32 kütüphane desteği Firestore'a göre çok daha olgun.

## Atık atma akışı

1. Uygulamada tür seçilir → Firestore'da `sessions/{id}` oluşur (`status: pending`)
2. Aynı anda RTDB'ye kutu komutu yazılır
3. ESP32 komutu görür → ilgili servoyu açar → `status: lidOpen`
4. IR sensör her atığı sayar → `depositedCount` güncellenir
5. Belirli süre hareket olmazsa kapak kapanır → `status: completed`
6. Uygulama puanı Firestore transaction'ı ile **bir kez** kullanıcıya ekler

## Proje yapısı

Her özellik (feature) Clean Architecture ile üç katmana ayrılmıştır:

```
lib/
├── core/                 # tema, sabitler, hata tipleri, Firebase sağlayıcıları
├── shared/widgets/       # ortak arayüz bileşenleri
└── features/
    ├── auth/             # kayıt, giriş, oturum
    ├── wallet/           # puan bakiyesi
    ├── recycling/        # QR okutma, tür seçimi, canlı oturum, ESP32 köprüsü
    └── rewards/          # ödül kataloğu, kod üretme, yemekhane doğrulaması
        ├── domain/       # iş kuralları — Firebase'i bilmez
        ├── data/         # Firebase ile konuşan tek katman
        └── presentation/ # ekranlar ve Riverpod sağlayıcıları
```

`firmware/` klasöründe ESP32'nin C++ kodu ve Wokwi simülasyon şeması bulunur.

## Kullanılan teknolojiler

| Alan | Teknoloji |
|---|---|
| Mobil | Flutter, Riverpod (durum yönetimi) |
| Arka uç | Firebase Auth, Cloud Firestore, Realtime Database |
| Donanım | ESP32, 3× servo motor, 3× IR engel algılama sensörü |
| Firmware | Arduino/C++, Firebase ESP Client |

## Geliştirme

```bash
flutter pub get
flutterfire configure     # Firebase bağlantısı (bir kez)
flutter run
```

Fiziksel donanım olmadan test edebilmek için iki geliştirme kolaylığı vardır ve
**yalnızca debug derlemede** görünür:

- Aktif oturum ekranındaki **donanım simülatörü** — kapak aç / adet say / bitir
- Ana sayfadaki **test QR kodu** — basılı etiket olmadan tarama denemek için

## Bilinen sınırlamalar

- Puan ve sayaç güncellemeleri istemci tarafında yapılıyor; sunucu tarafı doğrulama
  (Cloud Functions) henüz yok. Güvenlik kuralları başkasının verisine erişimi ve
  tek kullanımlık kodun yeniden kullanımını engeller, ancak kullanıcının kendi
  verisine müdahalesine karşı tam koruma sağlamaz.
- Yemekhane doğrulama paneli şimdilik aynı uygulama içindedir; ayrı bir personel
  rolü/girişi planlanmaktadır.
- QR kodu sabittir; kutuya monte edilecek ekranda periyodik değişen (dinamik) QR
  desteği planlanmaktadır.
