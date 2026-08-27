import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/recycling_remote_datasource.dart';
import '../../data/repositories/recycling_repository_impl.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../../domain/usecases/claim_session_points.dart';
import '../../domain/usecases/simulate_hardware_events.dart';
import '../../domain/usecases/start_recycling_session.dart';
import '../../domain/usecases/watch_recycling_session.dart';

final recyclingRemoteDataSourceProvider = Provider<RecyclingRemoteDataSource>((ref) {
  return RecyclingRemoteDataSource(ref.watch(firestoreProvider));
});

final recyclingRepositoryProvider = Provider<RecyclingRepository>((ref) {
  return RecyclingRepositoryImpl(ref.watch(recyclingRemoteDataSourceProvider));
});

final startRecyclingSessionProvider = Provider(
  (ref) => StartRecyclingSession(ref.watch(recyclingRepositoryProvider)),
);

final claimSessionPointsProvider = Provider(
  (ref) => ClaimSessionPoints(ref.watch(recyclingRepositoryProvider)),
);

final updateSessionStatusProvider = Provider(
  (ref) => UpdateSessionStatus(ref.watch(recyclingRepositoryProvider)),
);

final incrementDepositedCountProvider = Provider(
  (ref) => IncrementDepositedCount(ref.watch(recyclingRepositoryProvider)),
);

/// `.family`: aynı provider'ı FARKLI parametrelerle (burada: sessionId)
/// kullanmamızı sağlar. Her sessionId için ayrı bir akış oluşur.
final activeSessionProvider = StreamProvider.family<RecyclingSession, String>((ref, sessionId) {
  final watchSession = WatchRecyclingSession(ref.watch(recyclingRepositoryProvider));
  return watchSession(sessionId);
});
