import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recycling_session.dart';
import 'recycling_providers.dart';

/// Yarıda bırakılan oturumu belirli bir süre sonra otomatik kapatır.
///
/// Neden gerekli: kullanıcı atma ekranından çıkarsa oturum "lidOpen"
/// durumunda askıda kalıyordu — kapak açık kalıyor, o ana kadar sayılan
/// atıkların puanı da hiç işlenmiyordu. Bu sınıf hem oturumu kapatır
/// hem de o ana kadar sayılan adedin puanını kullanıcıya yazar.
class SessionAutoClose extends Notifier<void> {
  /// Ekrandan çıkıldıktan sonra oturumun kapanması için beklenen süre.
  /// Kullanıcı hemen geri dönerse iptal edilir.
  static const Duration bekleme = Duration(seconds: 10);

  Timer? _zamanlayici;

  /// O an ekranda AÇIK olan oturum. Açık bir oturum otomatik kapatılmaz.
  String? _ekrandakiOturum;

  @override
  void build() {
    // Provider yok edilirken bekleyen zamanlayıcı da iptal edilmeli,
    // yoksa uygulama kapandıktan sonra çalışmaya çalışır.
    ref.onDispose(() => _zamanlayici?.cancel());
  }

  /// Kullanıcı oturum ekranını açtı — bekleyen kapatmayı iptal et.
  void ekranaGirildi(String sessionId) {
    _ekrandakiOturum = sessionId;
    _zamanlayici?.cancel();
    _zamanlayici = null;
  }

  /// Kullanıcı oturum ekranından çıktı — geri dönmezse kapat.
  void ekrandanCikildi(String sessionId) {
    if (_ekrandakiOturum == sessionId) _ekrandakiOturum = null;
    _zamanla(sessionId);
  }

  /// Uygulama yeniden açıldığında geride kalmış oturumlar için.
  /// Ekranda açık olan ya da zaten sıraya alınmış oturumu tekrar
  /// zamanlamaz.
  void gerekiyorsaZamanla(String sessionId) {
    if (_ekrandakiOturum == sessionId) return;
    if (_zamanlayici != null) return;
    _zamanla(sessionId);
  }

  void _zamanla(String sessionId) {
    _zamanlayici?.cancel();
    _zamanlayici = Timer(bekleme, () async {
      _zamanlayici = null;
      await _kapat(sessionId);
    });
  }

  Future<void> _kapat(String sessionId) async {
    final repository = ref.read(recyclingRepositoryProvider);
    try {
      final oturum = await repository.watchSession(sessionId).first;
      // Bu arada tamamlanmışsa dokunma.
      if (oturum.status == SessionStatus.completed) return;

      await repository.updateStatus(sessionId, SessionStatus.completed);
      // Puanı da burada yazıyoruz: ekran kapalı olduğu için normalde
      // puanı ekleyen dinleyici çalışmıyor. claimPoints zaten taze
      // veriyi okuyup tek seferlik davranıyor, iki kez yazma riski yok.
      await repository.claimPoints(oturum);
    } catch (_) {
      // Ağ hatası vb. — sessizce geç. Oturum askıda kalırsa kullanıcı
      // ana sayfadaki uyarıdan tekrar girip bitirebilir.
    }
  }
}

final sessionAutoCloseProvider =
    NotifierProvider<SessionAutoClose, void>(SessionAutoClose.new);
