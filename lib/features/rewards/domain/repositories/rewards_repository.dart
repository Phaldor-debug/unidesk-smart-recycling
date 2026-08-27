import '../entities/redemption.dart';
import '../entities/reward.dart';

abstract class RewardsRepository {
  /// Aktif ödül kataloğunu CANLI izler (Firestore'daki `rewards` koleksiyonu).
  Stream<List<Reward>> watchRewards();

  /// Kullanıcının puanını düşer ve yeni bir kod üretir.
  /// Yeterli puan yoksa hata fırlatır (puan düşülmez, kod üretilmez).
  Future<Redemption> redeem({required String uid, required Reward reward});

  /// Kod ile AKTİF (henüz kullanılmamış) bir hakkı bulur.
  /// Yemekhane tarafı bunu çağırır. Bulamazsa null döner.
  Future<Redemption?> findActiveByCode(String code);

  /// Bir hakkı "kullanıldı" olarak işaretler — bir daha kullanılamaz.
  Future<void> markUsed(String redemptionId);
}
