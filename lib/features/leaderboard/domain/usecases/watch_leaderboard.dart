import '../entities/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';

class WatchLeaderboard {
  const WatchLeaderboard(this._repository);
  final LeaderboardRepository _repository;

  Stream<List<LeaderboardEntry>> call({int limit = 50}) {
    return _repository.watchTop(limit: limit);
  }
}
