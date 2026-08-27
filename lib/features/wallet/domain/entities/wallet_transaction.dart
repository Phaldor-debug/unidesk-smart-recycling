/// Puan hareketinin yönü.
enum TransactionKind {
  /// Atık atarak puan kazanıldı.
  earned,

  /// Ödül kullanılarak puan harcandı.
  spent,
}

/// Puan geçmişindeki tek bir satır. İki farklı kaynaktan (atık oturumları
/// ve ödül kullanımları) beslenir ama ekran ikisini tek tip olarak görür.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.kind,
    required this.title,
    required this.points,
    required this.date,
  });

  final String id;
  final TransactionKind kind;

  /// Ekranda görünecek açıklama (ör. "Plastik — 3 adet" / "Ücretsiz Yemek").
  final String title;

  /// Her zaman pozitif; yön `kind` ile belirtilir.
  final int points;

  /// Sunucu saatiyle oluşturulma zamanı. Henüz sunucudan dönmemişse null
  /// olabilir (Firestore serverTimestamp yazıldığı anda kısa süre boş gelir).
  final DateTime? date;
}
