import '../entities/reward.dart';
import '../repositories/rewards_repository.dart';

class WatchRewards {
  const WatchRewards(this._repository);
  final RewardsRepository _repository;

  Stream<List<Reward>> call() => _repository.watchRewards();
}
