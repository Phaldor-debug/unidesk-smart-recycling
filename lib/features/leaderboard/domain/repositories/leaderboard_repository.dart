import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  /// En yüksek puanlı kullanıcıları sıralı olarak CANLI izler.
  Stream<List<LeaderboardEntry>> watchTop({int limit});
}
