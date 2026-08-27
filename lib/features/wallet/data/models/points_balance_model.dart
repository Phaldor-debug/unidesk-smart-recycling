import '../../domain/entities/points_balance.dart';

class PointsBalanceModel extends PointsBalance {
  const PointsBalanceModel({required super.points});

  /// Firestore'dan gelen kullanıcı belgesini PointsBalanceModel'e çevirir.
  /// Belge yoksa veya 'points' alanı eksikse 0 varsayıyoruz — uygulama
  /// asla null yüzünden çökmez.
  factory PointsBalanceModel.fromMap(Map<String, dynamic>? map) {
    return PointsBalanceModel(points: (map?['points'] as int?) ?? 0);
  }
}
