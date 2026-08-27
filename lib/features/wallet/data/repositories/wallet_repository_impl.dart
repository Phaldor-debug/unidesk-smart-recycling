import '../../domain/entities/points_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remote);
  final WalletRemoteDataSource _remote;

  @override
  Stream<List<WalletTransaction>> watchTransactions(String uid) {
    return _remote.watchTransactions(uid);
  }

  @override
  Stream<PointsBalance> watchPointsBalance(String uid) {
    return _remote.watchPointsBalance(uid);
  }
}
