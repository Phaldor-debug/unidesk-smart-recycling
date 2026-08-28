import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/period.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../badges/presentation/providers/badge_providers.dart';
import 'leaderboard_providers.dart';

/// Bildirimleri kuran/gönderen tek nokta.
///
/// Uygulama açıldığında bir kez çalışır. İki bildirim var:
///
/// 1. **Ay bitiyor** — ayın son 3 günü, SADECE ilk 10'daysan. Şansı
///    olmayan kullanıcıyı rahatsız etmemek için bu koşul var.
/// 2. **Podyum sonucu** — geçen ayı ilk 3'te bitirdiysen, bir kez.
///
/// Sunucu gerektirmiyor: hepsi cihaz üzerinde zamanlanıyor.
class NotificationScheduler extends Notifier<void> {
  bool _calisti = false;

  @override
  void build() {
    ref.keepAlive();
  }

  /// Uygulama açılışında bir kez çağrılır.
  Future<void> kur() async {
    if (_calisti) return;
    _calisti = true;

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    try {
      await NotificationService.instance.izinIste();
      await _ayBitiyorHatirlatmasiKur(uid);
      await _podyumSonucunuBildir(uid);
    } catch (_) {
      // Bildirim kurulamazsa uygulama akışı etkilenmesin.
    }
  }

  Future<void> _ayBitiyorHatirlatmasiKur(String uid) async {
    // Sıralamayı bir kez oku — kullanıcı ilk 10'da mı?
    final siralama = await ref.read(leaderboardProvider.future);
    final sira = siralama.indexWhere((e) => e.uid == uid);

    // Listede yok ya da ilk 10'da değil: hatırlatma göndermiyoruz.
    // Ödül şansı olmayan kişiye "son 3 gün" demek rahatsız edici olur.
    if (sira == -1 || sira >= 10) {
      await NotificationService.instance.iptalEt(BildirimId.ayBitiyor);
      return;
    }

    final simdi = DateTime.now();
    final ayinSonGunu = DateTime(simdi.year, simdi.month + 1, 0).day;
    // Son 3 günün ilk günü, akşam 18:00 — insanların telefonuna baktığı
    // makul bir saat.
    final hatirlatmaGunu = ayinSonGunu - 2;
    final tarih = DateTime(simdi.year, simdi.month, hatirlatmaGunu, 18);

    await NotificationService.instance.zamanla(
      id: BildirimId.ayBitiyor,
      tarih: tarih,
      baslik: 'Ay bitiyor!',
      metin: 'Sıralamada ${sira + 1}. sıradasın. '
          'İlk 3 ödül kazanıyor — son 3 gün.',
    );
  }

  Future<void> _podyumSonucunuBildir(String uid) async {
    final repository = ref.read(badgeRepositoryProvider);

    // Geçen ay zaten değerlendirildiyse bildirim de gönderilmiştir.
    if (await repository.gecenAyDegerlendirildiMi(uid)) return;

    final gecenAy = await ref.read(previousMonthWinnersProvider.future);
    final sira = gecenAy.indexWhere((e) => e.uid == uid);
    if (sira == -1) return;

    const sirali = ['birinci', 'ikinci', 'üçüncü'];
    await NotificationService.instance.hemenGoster(
      id: BildirimId.podyumSonucu,
      baslik: 'Tebrikler! 🏆',
      metin: '${donemAdi(oncekiDonem())} sıralamasını '
          '${sirali[sira]} bitirdin. Ödülün seni bekliyor!',
    );
  }
}

final notificationSchedulerProvider =
    NotifierProvider<NotificationScheduler, void>(NotificationScheduler.new);
