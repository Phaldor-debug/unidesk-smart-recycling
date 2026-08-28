import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_datasource.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  const LeaderboardRepositoryImpl(this._remote);
  final LeaderboardRemoteDataSource _remote;

  @override
  Stream<List<LeaderboardEntry>> watchTop({int limit = 50}) {
    return _remote.watchTop(limit: limit);
  }
}
