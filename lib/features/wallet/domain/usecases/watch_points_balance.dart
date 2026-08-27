import '../entities/points_balance.dart';
import '../repositories/wallet_repository.dart';

/// "Puan bakiyesini izle" iş kuralı.
class WatchPointsBalance {
  const WatchPointsBalance(this._repository);
  final WalletRepository _repository;

  Stream<PointsBalance> call(String uid) => _repository.watchPointsBalance(uid);
}
