import '../entities/redemption.dart';
import '../entities/reward.dart';
import '../repositories/rewards_repository.dart';

class RedeemReward {
  const RedeemReward(this._repository);
  final RewardsRepository _repository;

  Future<Redemption> call({required String uid, required Reward reward}) {
    return _repository.redeem(uid: uid, reward: reward);
  }
}
