import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/period.dart';
import '../../data/datasources/leaderboard_remote_datasource.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/usecases/watch_leaderboard.dart';

final leaderboardRemoteDataSourceProvider = Provider<LeaderboardRemoteDataSource>((ref) {
  return LeaderboardRemoteDataSource(ref.watch(firestoreProvider));
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(ref.watch(leaderboardRemoteDataSourceProvider));
});

final watchLeaderboardProvider = Provider(
  (ref) => WatchLeaderboard(ref.watch(leaderboardRepositoryProvider)),
);

/// Bu ayın sıralaması, canlı.
final leaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(watchLeaderboardProvider).call();
});

/// Geçen ayın ilk üçü — kazananlar kalıcı olarak saklandığı için
/// ay değişse bile okunabiliyor.
final previousMonthWinnersProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(watchLeaderboardProvider).call(limit: 3, donem: oncekiDonem());
});
