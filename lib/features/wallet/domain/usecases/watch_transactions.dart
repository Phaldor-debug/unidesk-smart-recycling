import '../entities/wallet_transaction.dart';
import '../repositories/wallet_repository.dart';

class WatchTransactions {
  const WatchTransactions(this._repository);
  final WalletRepository _repository;

  Stream<List<WalletTransaction>> call(String uid) => _repository.watchTransactions(uid);
}
