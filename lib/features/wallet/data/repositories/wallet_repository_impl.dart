import '../../domain/entities/points_balance.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remote);
  final WalletRemoteDataSource _remote;

  @override
  Stream<PointsBalance> watchPointsBalance(String uid) {
    return _remote.watchPointsBalance(uid);
  }
}
