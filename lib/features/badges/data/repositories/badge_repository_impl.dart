import '../../domain/entities/badge.dart';
import '../../domain/entities/badge_stats.dart';
import '../../domain/repositories/badge_repository.dart';
import '../datasources/badge_remote_datasource.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  const BadgeRepositoryImpl(this._remote);
  final BadgeRemoteDataSource _remote;

  @override
  Stream<({BadgeStats stats, List<String> kazanilanlar})> watchBadgeState(String uid) {
    return _remote.watchBadgeState(uid);
  }

  @override
  Future<List<Achievement>> checkAndAward(String uid) => _remote.checkAndAward(uid);

  @override
  Future<void> gecenAyiDegerlendir(String uid) => _remote.gecenAyiDegerlendir(uid);

  @override
  Future<bool> gecenAyDegerlendirildiMi(String uid) =>
      _remote.gecenAyDegerlendirildiMi(uid);
}
