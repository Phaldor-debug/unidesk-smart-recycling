import '../repositories/recycling_repository.dart';

class SetDepositedCount {
  const SetDepositedCount(this._repository);
  final RecyclingRepository _repository;

  Future<void> call(String sessionId, int count) {
    return _repository.setDepositedCount(sessionId, count);
  }
}
