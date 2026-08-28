import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  /// Bir dönemin (ayın) en yüksek puanlı kullanıcılarını CANLI izler.
  /// `donem` verilmezse içinde bulunulan ay kullanılır.
  Stream<List<LeaderboardEntry>> watchTop({int limit, String? donem});
}
