/// Firestore koleksiyon adlarını tek yerde topluyoruz.
/// Bir koleksiyon adı değişirse tek dosya güncellenir, kod içinde
/// dağınık 'users' string'leri aramak zorunda kalmayız.
class FirestorePaths {
  FirestorePaths._(); // Bu sınıftan nesne üretilemez — sadece sabitler için var.

  static const String users = 'users';

  /// Her "atık atma oturumu" (tür seçildi -> kapak açıldı -> sayıldı ->
  /// tamamlandı) burada bir belge olarak tutulur. ESP32 (şimdilik simülatör)
  /// ile Flutter uygulaması BU koleksiyon üzerinden haberleşir.
  static const String sessions = 'sessions';

  /// Kullanıcının puanla satın aldığı hakları (ör. ücretsiz yemek) ve
  /// üretilen kodu tutar. Yemekhane tarafı kodu bu koleksiyonda arayıp
  /// "kullanıldı" olarak işaretler.
  static const String redemptions = 'redemptions';

  /// Puanla alınabilecek hakların KATALOĞU (ör. "Ücretsiz Yemek", 100 puan).
  /// Bilerek kod içinde değil burada — Firebase Console'dan (ileride bir
  /// admin panelinden) belge ekleyip/düzenleyip uygulamayı yeniden
  /// derlemeden ödül eklenebilsin diye.
  static const String rewards = 'rewards';

  /// Her kullanıcının HER AY için ayrı bir skor kaydı.
  /// Belge kimliği: "{uid}_{2026-08}".
  ///
  /// Neden ayrı koleksiyon: puan kullanıcı belgesinde tek bir alanda
  /// tutulsaydı, yeni ay başlayınca sıfırlanır ve geçen ayın sıralaması
  /// (dolayısıyla kazananlar) kaybolurdu. Aya özel kayıtla hiçbir ay
  /// silinmiyor, geçmiş aylar sonradan da sorgulanabiliyor.
  static const String monthlyScores = 'monthly_scores';

  /// Uygulama geneli sayaçlar (ör. toplam kayıt sayısı).
  /// Tek belge: stats/counters
  static const String stats = 'stats';
  static const String countersDoc = 'counters';
}
