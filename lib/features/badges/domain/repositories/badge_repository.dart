import '../entities/badge.dart';
import '../entities/badge_stats.dart';

abstract class BadgeRepository {
  /// Kullanıcının istatistikleri ve kazandığı rozet kimlikleri, canlı.
  Stream<({BadgeStats stats, List<String> kazanilanlar})> watchBadgeState(String uid);

  /// Hak edilmiş rozetleri verir, bonus puanı yazar, yeni kazanılanları döner.
  Future<List<Achievement>> checkAndAward(String uid);

  /// Geçen ayın sıralamasına göre podyum/şampiyon sayaçlarını günceller.
  Future<void> gecenAyiDegerlendir(String uid);

  Future<bool> gecenAyDegerlendirildiMi(String uid);
}
