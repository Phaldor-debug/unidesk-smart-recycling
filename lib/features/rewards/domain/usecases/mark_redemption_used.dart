import '../repositories/rewards_repository.dart';

/// Yemekhane tarafının kullanacağı işlem: kodu "kullanıldı" yapar.
class MarkRedemptionUsed {
  const MarkRedemptionUsed(this._repository);
  final RewardsRepository _repository;

  Future<void> call(String redemptionId) => _repository.markUsed(redemptionId);
}
