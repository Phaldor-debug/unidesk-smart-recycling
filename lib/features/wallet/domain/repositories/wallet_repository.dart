import '../entities/points_balance.dart';
import '../entities/wallet_transaction.dart';

/// Wallet ile ilgili sözleşme. Firebase'e dair hiçbir şey bilmez.
abstract class WalletRepository {
  /// Kullanıcının puan geçmişini (kazanç + harcama, tarihe göre yeniden
  /// eskiye) CANLI izler.
  Stream<List<WalletTransaction>> watchTransactions(String uid);

  /// uid'si verilen kullanıcının puan bakiyesini CANLI izler.
  /// Future değil Stream döner çünkü Firestore'daki değer her
  /// değiştiğinde (ör. ESP32 puan yazınca) yeni bir değer yayınlanmalı.
  Stream<PointsBalance> watchPointsBalance(String uid);
}
