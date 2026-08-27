import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../datasources/rewards_remote_datasource.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  const RewardsRepositoryImpl(this._remote);
  final RewardsRemoteDataSource _remote;

  @override
  Stream<List<Reward>> watchRewards() => _remote.watchRewards();

  @override
  Future<Redemption> redeem({required String uid, required Reward reward}) {
    return _remote.redeem(uid: uid, reward: reward);
  }

  @override
  Future<Redemption?> findActiveByCode(String code) => _remote.findActiveByCode(code);

  @override
  Future<void> markUsed(String redemptionId) => _remote.markUsed(redemptionId);
}
