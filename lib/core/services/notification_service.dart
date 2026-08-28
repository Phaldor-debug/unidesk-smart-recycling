import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Uygulamanın bildirim altyapısı.
///
/// TASARIM: bildirimler bilinçli olarak AZ. Ayda en fazla iki tane
/// gönderiliyor — "ay bitiyor" hatırlatması ve "podyum sonucu". Rozet
/// kazanımı için bildirim YOK, çünkü rozet her zaman uygulama açıkken
/// kazanılıyor ve zaten kutlama penceresi çıkıyor; üstüne bildirim
/// göndermek gereksiz tekrar olurdu.
///
/// Hepsi cihaz üzerinde zamanlanıyor — sunucu (Cloud Functions) ve
/// dolayısıyla ücretli plan gerektirmiyor.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _eklenti = FlutterLocalNotificationsPlugin();
  bool _hazir = false;

  /// Web'de yerel bildirim desteklenmiyor; orada tüm çağrılar sessizce
  /// hiçbir şey yapmaz ki geliştirme sırasında hata almayalım.
  bool get _desteklenmiyor => kIsWeb;

  static const _kanal = AndroidNotificationChannel(
    'unidesk_genel',
    'Ünidesk',
    description: 'Ay sonu hatırlatmaları ve sıralama sonuçları',
    importance: Importance.defaultImportance,
  );

  Future<void> baslat() async {
    if (_desteklenmiyor || _hazir) return;

    tz.initializeTimeZones();

    const ayarlar = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _eklenti.initialize(settings: ayarlar);

    await _eklenti
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_kanal);

    _hazir = true;
  }

  /// Android 13+ ve iOS bildirim izni ister.
  /// Kullanıcı reddederse sessizce devam edilir — bildirimler uygulamanın
  /// çalışması için zorunlu değil.
  Future<void> izinIste() async {
    if (_desteklenmiyor) return;
    await baslat();

    await _eklenti
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _eklenti
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails get _detaylar => NotificationDetails(
        android: AndroidNotificationDetails(
          _kanal.id,
          _kanal.name,
          channelDescription: _kanal.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// Hemen gösterilen bildirim (ör. geçen ayı podyumda bitirdin).
  Future<void> hemenGoster({
    required int id,
    required String baslik,
    required String metin,
  }) async {
    if (_desteklenmiyor) return;
    await baslat();
    await _eklenti.show(
      id: id,
      title: baslik,
      body: metin,
      notificationDetails: _detaylar,
    );
  }

  /// Belirli bir tarihe bildirim kurar. Tarih geçmişse hiçbir şey yapmaz.
  ///
  /// `inexactAllowWhileIdle`: kesin zamanlı alarm Android 12+'da ayrı bir
  /// kullanıcı izni istiyor. Bir hatırlatma için buna değmez; birkaç
  /// dakikalık sapma kabul edilebilir.
  Future<void> zamanla({
    required int id,
    required DateTime tarih,
    required String baslik,
    required String metin,
  }) async {
    if (_desteklenmiyor) return;
    await baslat();

    if (tarih.isBefore(DateTime.now())) return;

    try {
      await _eklenti.zonedSchedule(
        id: id,
        title: baslik,
        body: metin,
        scheduledDate: tz.TZDateTime.from(tarih, tz.local),
        notificationDetails: _detaylar,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (hata) {
      // Zamanlama başarısız olursa uygulama akışı bozulmasın.
      if (kDebugMode) debugPrint('[bildirim] zamanlanamadi: $hata');
    }
  }

  Future<void> iptalEt(int id) async {
    if (_desteklenmiyor) return;
    await _eklenti.cancel(id: id);
  }
}

/// Bildirim kimlikleri — tek yerde tutuluyor ki aynı kimlik iki farklı
/// bildirimde kullanılıp birbirini ezmesin.
class BildirimId {
  BildirimId._();

  /// Ay bitmeden önceki hatırlatma.
  static const int ayBitiyor = 1001;

  /// Geçen ayı podyumda bitirme duyurusu.
  static const int podyumSonucu = 1002;
}
