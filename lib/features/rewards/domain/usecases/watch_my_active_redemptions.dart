import '../entities/redemption.dart';
import '../repositories/rewards_repository.dart';

class WatchMyActiveRedemptions {
  const WatchMyActiveRedemptions(this._repository);
  final RewardsRepository _repository;

  Stream<List<Redemption>> call(String uid) => _repository.watchMyActiveRedemptions(uid);
}
