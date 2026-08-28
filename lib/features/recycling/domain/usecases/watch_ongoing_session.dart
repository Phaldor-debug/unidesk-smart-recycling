import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

class WatchOngoingSession {
  const WatchOngoingSession(this._repository);
  final RecyclingRepository _repository;

  Stream<RecyclingSession?> call(String uid) => _repository.watchOngoingSession(uid);
}
