import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/bin_realtime_datasource.dart';
import '../../data/datasources/recycling_remote_datasource.dart';
import '../../data/repositories/bin_command_repository_impl.dart';
import '../../data/repositories/recycling_repository_impl.dart';
import '../../domain/entities/bin_command.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/repositories/bin_command_repository.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../../domain/usecases/apply_hardware_update.dart';
import '../../domain/usecases/claim_session_points.dart';
import '../../domain/usecases/publish_bin_command.dart';
import '../../domain/usecases/simulate_hardware_events.dart';
import '../../domain/usecases/start_recycling_session.dart';
import '../../domain/usecases/watch_bin_command.dart';
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

final applyHardwareUpdateProvider = Provider(
  (ref) => ApplyHardwareUpdate(ref.watch(recyclingRepositoryProvider)),
);

/// `.family`: aynı provider'ı FARKLI parametrelerle (burada: sessionId)
/// kullanmamızı sağlar. Her sessionId için ayrı bir akış oluşur.
final activeSessionProvider = StreamProvider.family<RecyclingSession, String>((ref, sessionId) {
  final watchSession = WatchRecyclingSession(ref.watch(recyclingRepositoryProvider));
  return watchSession(sessionId);
});

// --- ESP32 <-> uygulama köprüsü (Realtime Database) ---

final binRealtimeDataSourceProvider = Provider<BinRealtimeDataSource>((ref) {
  return BinRealtimeDataSource(ref.watch(realtimeDatabaseProvider));
});

final binCommandRepositoryProvider = Provider<BinCommandRepository>((ref) {
  return BinCommandRepositoryImpl(ref.watch(binRealtimeDataSourceProvider));
});

final publishBinCommandProvider = Provider(
  (ref) => PublishBinCommand(ref.watch(binCommandRepositoryProvider)),
);

/// Bir kutunun canlı komutunu (ESP32'nin yazdığı/yazacağı) izler.
final binCommandProvider = StreamProvider.family<BinCommand?, String>((ref, binId) {
  final watchCommand = WatchBinCommand(ref.watch(binCommandRepositoryProvider));
  return watchCommand(binId);
});
