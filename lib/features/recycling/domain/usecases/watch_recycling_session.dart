import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

class WatchRecyclingSession {
  const WatchRecyclingSession(this._repository);
  final RecyclingRepository _repository;

  Stream<RecyclingSession> call(String sessionId) => _repository.watchSession(sessionId);
}
