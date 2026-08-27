/*
  Ünidesk Akıllı Geri Dönüşüm Kutusu — ESP32 Firmware
  =====================================================
  Bu kod, Flutter uygulamasıyla Firebase Realtime Database üzerinden
  konuşur. Uygulama tarafında yazdığımız yol AYNEN burada:

    /bin_commands/{BIN_ID} = {
      sessionId:      string   (hangi oturum)
      wasteType:      string   ("plastik" | "kagit" | "cam")
      status:         string   ("pending" | "lidOpen" | "completed")
      depositedCount: number   (o oturumda sayılan adet)
    }

  Akış:
    1) status "pending" görülür -> ilgili servo açılır, status "lidOpen" yapılır
    2) "lidOpen" iken IR sensör her algılamada depositedCount +1 yazılır
    3) Birkaç saniye yeni algılama olmazsa -> servo kapanır, status "completed"
    4) Flutter uygulaması "completed"i görüp puanı öğrenciye ekler (bu kod
       puanla hiç ilgilenmez, sadece kapak+sayım'dan sorumlu)

  Wokwi'de SANAL test için:
    - WiFi: "Wokwi-GUEST" (şifresiz, Wokwi'nin simülasyonlara verdiği
      gerçek internete çıkan sanal ağ)
    - 3 IR sensör yerine 3 buton var (Wokwi'nin hazır sensör kütüphanesinde
      "IR engel algılama" parçası yok; butona basmak = "atık algılandı"
      demek). Gerçek donanımda bu satırların DEĞİŞMESİNE gerek yok, çünkü
      ikisi de aynı şekilde dijital LOW/HIGH okunuyor.

  Gerçek donanıma yüklerken (45 gün sonra):
    - WIFI_SSID / WIFI_PASSWORD'ü gerçek ağ bilgileriyle değiştir
    - Kütüphaneler (Arduino IDE > Library Manager):
        "Firebase ESP Client" (mobizt)
        "ESP32Servo"
*/

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>

// --- WiFi ---
#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

// --- Firebase ---
// API_KEY: Firebase Console > Project Settings > General > Web API Key
// (unidesk-geri-donusum projesinin Flutter tarafında zaten kullandığımız
// anahtarla aynı — lib/firebase_options.dart içindeki 'web' apiKey'i.)
#define API_KEY "AIzaSyBl1R2UtKbLjvi2WYDCHakgIxvlXrQrlAY"
#define DATABASE_URL "https://unidesk-geri-donusum-default-rtdb.europe-west1.firebasedatabase.app"

// Şimdilik tek bir sabit kutu id'si kullanıyoruz — Flutter tarafındaki
// AppConstants.demoBinId ile AYNI olmalı.
#define BIN_ID "demo-bin-01"

// --- Pin bağlantıları ---
const int SERVO_PIN_PLASTIK = 13;
const int SERVO_PIN_KAGIT = 12;
const int SERVO_PIN_CAM = 14;

const int IR_PIN_PLASTIK = 27;
const int IR_PIN_KAGIT = 26;
const int IR_PIN_CAM = 25;

const int SERVO_ACIK_ACI = 90;   // kapak açık pozisyonu
const int SERVO_KAPALI_ACI = 0;  // kapak kapalı pozisyonu

// Bu kadar süre (ms) yeni bir atık algılanmazsa oturumu otomatik bitir.
const unsigned long BOSTA_KALMA_SURESI_MS = 5000;

// --- Firebase nesneleri ---
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

Servo servoPlastik, servoKagit, servoCam;

// O an işlenen oturumun durumu (yerel takip; RTDB tek doğruluk kaynağı
// olsa da, "aynı komutu tekrar tekrar işleme" gibi durumları önlemek için)
String islenenSessionId = "";
String aktifTur = "";
int yerelSayac = 0;
unsigned long sonAlgilamaZamani = 0;
bool kapakAcik = false;

// Sensörün bir ÖNCEKİ okunan hali. Oturum başında bilerek sıfırlanır:
// aksi halde önceki oturumdan kalan LOW değeri yüzünden ilk algılama
// kaçırılabiliyordu. (Eskiden sensorleriOku() içinde `static` idi ve
// üç sensör bunu paylaşıyordu — tür değişince yanlış davranıyordu.)
bool oncekiSensorDurumu = HIGH;

// RTDB'ye yazılamamış sayaç var mı? WiFi anlık koptuğunda sayım
// kaybolmasın diye, yazma başarısız olursa bayrak açılır ve sonraki
// döngülerde tekrar denenir.
bool sayacYazilmayiBekliyor = false;

void setup() {
  Serial.begin(115200);

  servoPlastik.attach(SERVO_PIN_PLASTIK);
  servoKagit.attach(SERVO_PIN_KAGIT);
  servoCam.attach(SERVO_PIN_CAM);
  servoPlastik.write(SERVO_KAPALI_ACI);
  servoKagit.write(SERVO_KAPALI_ACI);
  servoCam.write(SERVO_KAPALI_ACI);

  // IR sensör (ya da Wokwi'de buton) pinleri: INPUT_PULLUP -> normalde
  // HIGH okunur, tetiklenince (veya butona basılınca) LOW'a düşer.
  pinMode(IR_PIN_PLASTIK, INPUT_PULLUP);
  pinMode(IR_PIN_KAGIT, INPUT_PULLUP);
  pinMode(IR_PIN_CAM, INPUT_PULLUP);

  wifiyeBaglan();
  firebaseyeBaglan();
}

void loop() {
  // Firebase-ESP-Client'ın bağlantı/token yenileme işlerini yürütmesi için
  // gerekli — bu satır olmadan token süresi dolunca istekler sessizce
  // başarısız olabilir.
  if (!Firebase.ready()) return;

  if (!kapakAcik) {
    // Boştayız: yeni bir "pending" komut var mı diye kontrol ediyoruz.
    komutlariKontrolEt();
  } else {
    // Bir kapak açık: sensörleri oku, boşta kalma süresini kontrol et.
    sensorleriOku();
    if (millis() - sonAlgilamaZamani > BOSTA_KALMA_SURESI_MS) {
      oturumuBitir();
    }
  }

  delay(200); // Wokwi/gerçek donanımda gereksiz sık sorgulamayı önler.
}

void wifiyeBaglan() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("WiFi'ye baglaniliyor");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }
  Serial.println("\nWiFi baglandi: " + WiFi.localIP().toString());
}

void firebaseyeBaglan() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Anonim giriş: email/şifre YOK, kütüphane Firebase.begin() içinde
  // otomatik olarak anonim bir hesap açar. Firebase Console'da
  // Authentication > Sign-in method > Anonymous AÇIK olmalı.
  auth.user.email = "";
  auth.user.password = "";

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("Firebase'e baglaniliyor (anonim)...");
}

/// RTDB'deki komutu okur; yeni bir "pending" oturum görürse kapağı açar.
void komutlariKontrolEt() {
  if (!Firebase.RTDB.getJSON(&fbdo, "/bin_commands/" BIN_ID)) return;

  FirebaseJson *json = fbdo.jsonObjectPtr();
  FirebaseJsonData veri;

  json->get(veri, "sessionId");
  String gelenSessionId = veri.stringValue;

  json->get(veri, "status");
  String durum = veri.stringValue;

  json->get(veri, "wasteType");
  String tur = veri.stringValue;

  // Zaten işlediğimiz oturumu tekrar işleme.
  if (gelenSessionId == "" || gelenSessionId == islenenSessionId) return;
  if (durum != "pending") return;

  Serial.println("Yeni oturum: " + gelenSessionId + " (" + tur + ")");
  islenenSessionId = gelenSessionId;
  aktifTur = tur;
  yerelSayac = 0;
  kapakAcik = true;
  sonAlgilamaZamani = millis();
  // Sensör geçmişini sıfırla — önceki oturumdan kalan LOW değeri
  // yüzünden bu oturumun ilk algılaması kaçırılmasın.
  oncekiSensorDurumu = HIGH;
  sayacYazilmayiBekliyor = false;

  servoIcinAc(tur);
  durumYaz("lidOpen");
}

void servoIcinAc(String tur) {
  if (tur == "plastik") servoPlastik.write(SERVO_ACIK_ACI);
  else if (tur == "kagit") servoKagit.write(SERVO_ACIK_ACI);
  else if (tur == "cam") servoCam.write(SERVO_ACIK_ACI);
}

void servoIcinKapat(String tur) {
  if (tur == "plastik") servoPlastik.write(SERVO_KAPALI_ACI);
  else if (tur == "kagit") servoKagit.write(SERVO_KAPALI_ACI);
  else if (tur == "cam") servoCam.write(SERVO_KAPALI_ACI);
}

/// Aktif türün IR pinini (ya da Wokwi'de butonunu) okur, LOW (tetiklendi)
/// görürse sayaç +1 yapıp RTDB'ye yazar. Basit bir "debounce" ile aynı
/// algılamayı birden çok kez saymayı önlüyoruz.
void sensorleriOku() {
  int pin = -1;
  if (aktifTur == "plastik") pin = IR_PIN_PLASTIK;
  else if (aktifTur == "kagit") pin = IR_PIN_KAGIT;
  else if (aktifTur == "cam") pin = IR_PIN_CAM;
  if (pin == -1) return;

  bool suankiDurum = digitalRead(pin);

  // HIGH -> LOW geçişi: yeni bir algılama (bir kez basılıp bırakılan
  // butonu/sensörü TEK algılama sayar, basılı tutmayı değil).
  if (oncekiSensorDurumu == HIGH && suankiDurum == LOW) {
    yerelSayac++;
    sonAlgilamaZamani = millis();
    Serial.println("Algilama! Sayac: " + String(yerelSayac));
    sayacYazilmayiBekliyor = true;
  }
  oncekiSensorDurumu = suankiDurum;

  // Yazılamamış sayaç varsa (yeni algılama ya da önceki denemenin
  // başarısızlığı) tekrar dene. Böylece anlık bağlantı sorunu
  // atılan atığın sayılmamasına yol açmaz.
  if (sayacYazilmayiBekliyor) {
    if (sayaciYaz(yerelSayac)) {
      sayacYazilmayiBekliyor = false;
    } else {
      Serial.println("Sayac yazilamadi, tekrar denenecek.");
    }
  }
}

bool durumYaz(String durum) {
  return Firebase.RTDB.setString(&fbdo, "/bin_commands/" BIN_ID "/status", durum);
}

bool sayaciYaz(int adet) {
  return Firebase.RTDB.setInt(&fbdo, "/bin_commands/" BIN_ID "/depositedCount", adet);
}

void oturumuBitir() {
  // ÖNCE bekleyen sayacı yazmayı dene, SONRA "completed" bildir.
  // Sıra önemli: uygulama "completed" görünce puanı hesaplayıp
  // kilitliyor — sayaç o an eksikse kullanıcı puanını kaybederdi.
  if (sayacYazilmayiBekliyor) {
    if (sayaciYaz(yerelSayac)) {
      sayacYazilmayiBekliyor = false;
    } else {
      // Yazamadık: oturumu KAPATMIYORUZ, sonraki döngüde tekrar denenecek.
      Serial.println("Bitirme ertelendi: sayac henuz yazilamadi.");
      return;
    }
  }

  if (!durumYaz("completed")) {
    Serial.println("Bitirme ertelendi: durum yazilamadi.");
    return; // Kapağı da açık bırakıyoruz; bağlantı gelince tekrar denenir.
  }

  Serial.println("Oturum bitti. Toplam: " + String(yerelSayac));
  servoIcinKapat(aktifTur);

  kapakAcik = false;
  aktifTur = "";
  // islenenSessionId BİLEREK sıfırlanmıyor: aynı sessionId'yi tekrar
  // "pending" olarak görürsek yeniden işlemeyelim diye.
}
