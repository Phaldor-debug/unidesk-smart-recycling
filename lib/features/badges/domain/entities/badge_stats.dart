import '../../../recycling/domain/entities/waste_type.dart';

/// Rozet koşullarının değerlendirildiği kullanıcı istatistikleri.
///
/// Firestore'daki kullanıcı belgesinden okunur. Rozet tanımları sadece
/// bu nesneye bakar — böylece yeni bir rozet eklemek için veri katmanına
/// dokunmak gerekmez.
class BadgeStats {
  const BadgeStats({
    required this.totalItems,
    required this.itemsByType,
    required this.currentStreak,
    required this.activeDaysThisMonth,
    required this.registrationNo,
    required this.podiumFinishes,
    required this.championFinishes,
  });

  /// Bugüne kadar atılan toplam atık adedi.
  final int totalItems;

  /// Tür bazlı adetler.
  final Map<WasteType, int> itemsByType;

  /// Üst üste atık atılan gün sayısı.
  final int currentStreak;

  /// Bu ay atık atılan FARKLI gün sayısı (üst üste olmak zorunda değil).
  final int activeDaysThisMonth;

  /// Kaçıncı kayıtlı kullanıcı olduğu. Bilinmiyorsa 0.
  final int registrationNo;

  /// Bir ayı ilk 3'te bitirme sayısı.
  final int podiumFinishes;

  /// Bir ayı 1. bitirme sayısı.
  final int championFinishes;

  int tur(WasteType type) => itemsByType[type] ?? 0;

  /// Geri dönüşüme kazandırılan atıkların önlediği tahmini CO₂ (kg).
  ///
  /// Katsayılar `WasteTypeX.co2GramPerItem` içinde, varsayımlarıyla
  /// birlikte belgelenmiş durumda.
  double get co2Kg {
    var gram = 0.0;
    for (final tip in WasteType.values) {
      gram += tur(tip) * tip.co2GramPerItem;
    }
    return gram / 1000;
  }
}
