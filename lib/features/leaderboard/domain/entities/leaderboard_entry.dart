/// Sıralama tablosundaki tek bir satır.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.rank,
  });

  final String uid;

  /// Ham ad soyad. Ekranda gösterilirken `gizliAd` kullanılır.
  final String displayName;

  final int points;

  /// 1'den başlayan sıra numarası.
  final int rank;

  /// Ad tam, SOYAD SANSÜRLÜ hali — "Berke Akyıldız" -> "Berke A***".
  ///
  /// Sıralama herkese açık olduğu için tam soyadı göstermek gereksiz bir
  /// kişisel veri paylaşımı olurdu; baş harf, kişinin kendini tanıması
  /// için yeterli.
  String get gizliAd {
    final temiz = displayName.trim();
    if (temiz.isEmpty) return 'İsimsiz Kullanıcı';

    final parcalar = temiz.split(RegExp(r'\s+'));
    if (parcalar.length == 1) return parcalar.first;

    final ad = parcalar.sublist(0, parcalar.length - 1).join(' ');
    final soyad = parcalar.last;
    return '$ad ${soyad[0].toUpperCase()}***';
  }
}
