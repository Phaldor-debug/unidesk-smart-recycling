import '../../domain/entities/recycling_session.dart';
import '../../domain/entities/waste_type.dart';
import '../../domain/repositories/recycling_repository.dart';
import '../datasources/recycling_remote_datasource.dart';

class RecyclingRepositoryImpl implements RecyclingRepository {
  const RecyclingRepositoryImpl(this._remote);
  final RecyclingRemoteDataSource _remote;

  @override
  Future<String> startSession({
    required String uid,
    required String binId,
    required WasteType wasteType,
  }) {
    return _remote.startSession(uid: uid, binId: binId, wasteType: wasteType);
  }

  @override
  Stream<RecyclingSession> watchSession(String sessionId) {
    return _remote.watchSession(sessionId);
  }

  @override
  Future<void> claimPoints(RecyclingSession session) => _remote.claimPoints(session);

  @override
  Future<void> updateStatus(String sessionId, SessionStatus status) {
    return _remote.updateStatus(sessionId, status);
  }

  @override
  Future<void> incrementDepositedCount(String sessionId) {
    return _remote.incrementDepositedCount(sessionId);
  }

  @override
  Future<void> setDepositedCount(String sessionId, int count) {
    return _remote.setDepositedCount(sessionId, count);
  }
}
