import '../entities/redemption.dart';
import '../repositories/rewards_repository.dart';

/// Yemekhane tarafının kullanacağı sorgu: koddan aktif hakkı bulur.
class FindRedemptionByCode {
  const FindRedemptionByCode(this._repository);
  final RewardsRepository _repository;

  Future<Redemption?> call(String code) => _repository.findActiveByCode(code);
}
