# Ünidesk ESP32 Firmware

Bu klasördeki kod, fiziksel donanım gelmeden **Wokwi** (tarayıcı tabanlı ESP32
simülatörü) üzerinde test edilmek üzere yazıldı. Gerçek Firebase'e bağlanır —
yani burada test ettiğin akış, gerçek donanımda BİREBİR aynı çalışır.

## Wokwi'de sanal test (kurulum gerektirmez, tarayıcıdan)

1. [wokwi.com](https://wokwi.com) → ücretsiz hesap oluştur / giriş yap
2. **"New Project" → "ESP32"** seç
3. Sol taraftaki `sketch.ino` sekmesindeki örnek kodu SİL, bu klasördeki
   **`unidesk_bin.ino`** dosyasının içeriğini yapıştır
4. Üstte **"diagram.json"** sekmesine geç, içeriğini SİL, bu klasördeki
   **`diagram.json`** dosyasının içeriğini yapıştır
5. Sol üstte **"Library Manager"** (kitap ikonu) → şu iki kütüphaneyi ekle:
   - `Firebase ESP Client` (yazar: mobizt)
   - `ESP32Servo`
6. Yeşil **▶ (Play/Start Simulation)** butonuna bas

## Neyi görmelisin

1. Alttaki **Serial Monitor**'da: `WiFi baglandi`, `Firebase'e baglaniliyor` yazıları
2. Flutter uygulamasında (Chrome veya telefon) **Atık At → Plastik** seçip
   oturum başlat
3. Birkaç saniye içinde Wokwi'deki **Serial Monitor**'da `Yeni oturum: ...`
   yazısı ve **Plastik servosunun döndüğünü** görmelisin
4. Wokwi'deki **Plastik IR** butonuna birkaç kez tıkla — her tıklama bir
   "atık algılandı" demek
5. Uygulamadaki `ActiveSessionPage`'de sayacın **gerçek zamanlı arttığını**
   gör (artık simülatör panelinden değil, gerçek — sanal da olsa — donanımdan geliyor)
6. ~5 saniye butona basmazsan servo kapanır, oturum "completed" olur,
   uygulamada puan eklenir

## Pin haritası (gerçek donanıma montajda da AYNI kullanılacak)

| Parça | ESP32 Pin |
|---|---|
| Servo — Plastik | GPIO 13 |
| Servo — Kağıt | GPIO 12 |
| Servo — Cam | GPIO 14 |
| IR Sensör — Plastik | GPIO 27 |
| IR Sensör — Kağıt | GPIO 26 |
| IR Sensör — Cam | GPIO 25 |

## Neden buton, IR sensör değil?

Wokwi'nin hazır parça kütüphanesinde gerçek bir "IR engel algılama sensörü"
yok. Buton ile IR sensör, yazılım açısından **birebir aynı davranır** —
ikisi de bir pini LOW/HIGH yapar. Gerçek donanıma geçince koda HİÇ
dokunmana gerek yok, sadece butonun yerini gerçek sensör alacak.

## Gerçek donanıma yüklerken (45 gün sonra, Alanya'da)

1. [Arduino IDE](https://www.arduino.cc/en/software) kur
2. **File → Preferences** → "Additional Boards Manager URLs" kısmına ekle:
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. **Tools → Board → Boards Manager** → `esp32` ara, kur
4. **Tools → Manage Libraries** → `Firebase ESP Client` (mobizt) ve
   `ESP32Servo` kütüphanelerini kur
5. `unidesk_bin.ino`'yu aç, dosyanın en üstündeki `WIFI_SSID` /
   `WIFI_PASSWORD`'ü gerçek WiFi bilgileriyle değiştir
6. ESP32'yi USB ile bağla, doğru portu seç, **Upload**

## Bilinçli sınırlamalar (şimdilik)

- Tek kutu (`BIN_ID = "demo-bin-01"`) destekleniyor — çoklu kutu ileride
  eklenebilir (binId'yi sabit değil, kutunun kendi ayarından okumak yeterli)
- Anonim Firebase Auth kullanılıyor — herhangi bir cihaz kimliği doğrulaması
  yok, bu bir prototip için kabul edilebilir ama üretimde cihaza özel kimlik
  düşünülebilir
