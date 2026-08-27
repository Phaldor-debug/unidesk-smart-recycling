enum RedemptionStatus { active, used }

extension RedemptionStatusX on RedemptionStatus {
  String get id => name;

  static RedemptionStatus fromId(String id) {
    return RedemptionStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => RedemptionStatus.active,
    );
  }
}

/// Kullanıcının puanla satın aldığı bir hak ve buna karşılık üretilen kod.
class Redemption {
  const Redemption({
    required this.id,
    required this.uid,
    required this.rewardId,
    required this.rewardTitle,
    required this.code,
    required this.status,
  });

  final String id;
  final String uid;
  final String rewardId;

  /// Ödülün redeem edildiği ANDAKİ adı (denormalize edilmiş kopya).
  /// Neden kopyalıyoruz: yarın admin "Ücretsiz Yemek"i silse/adını
  /// değiştirse bile, öğrencinin GEÇMİŞ kaydı "ne aldığını" hâlâ doğru
  /// gösterir — canlı bir Reward referansı olsaydı bu bilgi kaybolurdu.
  final String rewardTitle;

  /// Yemekhanede gösterilecek/söylenecek kısa kod (ör. "482913").
  final String code;
  final RedemptionStatus status;
}
