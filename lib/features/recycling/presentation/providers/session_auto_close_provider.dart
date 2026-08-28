import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recycling_session.dart';
import 'recycling_providers.dart';

/// Yarıda bırakılan oturumu kapatır.
///
/// Kullanıcı atma ekranından çıktığı ANDA oturum bitirilir: o ana kadar
/// sayılan atıkların puanı yazılır ve oturum "tamamlandı" olur. Beklemeli
/// bir sürüm denendi ama ekrandan çıkınca "devam eden işlemin var" uyarısı
/// gereksizce asılı kalıyordu; kullanıcı için de "çıktım demek bitti demek"
/// daha anlaşılır.
///
/// Kapağın fiziksel olarak kapanması ESP32'nin işi: firmware kendi
/// 5 saniyelik boşta kalma sayacıyla servoyu kapatıyor. Buradaki kapatma
/// oturumu ve puanı sonlandırır, donanıma komut göndermez.
class SessionAutoClose extends Notifier<void> {
  /// O an ekranda AÇIK olan oturum. Açık bir oturum kapatılmaz.
  ///
  /// Bu bilgi ekranlar arasında taşınıyor; provider bir an için kimse
  /// dinlemediği için atılırsa bilgi kaybolur ve aktif oturum yanlışlıkla
  /// kapatılabilirdi. keepAlive bunu engelliyor.
  String? _ekrandakiOturum;

  /// Aynı oturumu iki kez kapatmaya çalışmayalım (çıkış + ana sayfa
  /// dinleyicisi arka arkaya tetiklenebiliyor).
  final Set<String> _kapatiliyor = {};

  @override
  void build() {
    ref.keepAlive();
  }

  /// Kullanıcı oturum ekranını açtı — bu oturum artık korumalı.
  ///
  /// Oturumu OLUŞTURAN ekran da bunu çağırmalı: aksi halde Firestore'dan
  /// gelen "devam eden oturum" bildirimi, kullanıcı daha atma ekranına
  /// varmadan oturumu kapatabilir.
  void ekranaGirildi(String sessionId) {
    _ekrandakiOturum = sessionId;
  }

  /// Kullanıcı oturum ekranından çıktı — oturumu hemen bitir.
  void ekrandanCikildi(String sessionId) {
    if (_ekrandakiOturum == sessionId) _ekrandakiOturum = null;
    _kapat(sessionId);
  }

  /// Uygulama yeniden açıldığında geride kalmış oturumlar için.
  /// Ekranda açık olan oturuma dokunmaz.
  void gerekiyorsaKapat(String sessionId) {
    if (_ekrandakiOturum == sessionId) return;
    _kapat(sessionId);
  }

  Future<void> _kapat(String sessionId) async {
    if (_kapatiliyor.contains(sessionId)) return;
    _kapatiliyor.add(sessionId);

    final repository = ref.read(recyclingRepositoryProvider);
    try {
      _log('kapatiliyor: $sessionId');
      final oturum = await repository.watchSession(sessionId).first;
      // Bu arada tamamlanmışsa dokunma.
      if (oturum.status == SessionStatus.completed) {
        _log('zaten tamamlanmis: $sessionId');
        return;
      }

      await repository.updateStatus(sessionId, SessionStatus.completed);
      // Puanı da burada yazıyoruz: ekran kapalı olduğu için normalde
      // puanı ekleyen dinleyici çalışmıyor. claimPoints zaten taze
      // veriyi okuyup tek seferlik davranıyor, iki kez yazma riski yok.
      await repository.claimPoints(oturum);
      _log('kapatildi: $sessionId '
          '(${oturum.depositedCount} adet, ${oturum.pointsEarned} puan)');
    } catch (hata, iz) {
      // Oturum askıda kalır; kullanıcı ana sayfadaki "devam eden işlem"
      // uyarısından tekrar girip bitirebilir.
      _log('KAPATILAMADI ($sessionId): $hata');
      _log(iz.toString());
    } finally {
      _kapatiliyor.remove(sessionId);
    }
  }
}

/// Tanılama günlüğü — yalnızca geliştirme derlemesinde yazar.
/// `debugPrint` release'de de çalıştığı için doğrudan kullanmıyoruz:
/// yayınlanan uygulamada oturum kimlikleri konsola düşmesin.
void _log(String mesaj) {
  if (kDebugMode) debugPrint('[oturum] $mesaj');
}

final sessionAutoCloseProvider =
    NotifierProvider<SessionAutoClose, void>(SessionAutoClose.new);
