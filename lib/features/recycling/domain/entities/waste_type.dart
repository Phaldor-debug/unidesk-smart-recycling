/// 3 gözlü kutunun her biri bir atık türüne karşılık gelir.
/// Yeni bir göz eklemek istersen sadece buraya bir değer eklemen yeter —
/// derleyici seni `label`/`pointsPerItem`'da eksik bıraktığın yer için uyarır.
enum WasteType { plastik, kagit, cam }

extension WasteTypeX on WasteType {
  /// Ekranda gösterilecek Türkçe ad.
  String get label => switch (this) {
        WasteType.plastik => 'Plastik',
        WasteType.kagit => 'Kağıt',
        WasteType.cam => 'Cam',
      };

  /// Bu türden 1 adet atık kaç puan kazandırır. Puan kuralını değiştirmek
  /// istediğinde SADECE burayı değiştirmen yeter — kodun başka hiçbir
  /// yerinde puan hesaplaması yapılmıyor.
  int get pointsPerItem => switch (this) {
        WasteType.plastik => 10,
        WasteType.kagit => 5,
        WasteType.cam => 15,
      };

  /// Bu türden BİR adet geri dönüştürüldüğünde önlenen tahmini CO₂ (gram).
  ///
  /// Nasıl hesaplandı (kodda saklı kalmasın diye açıkça yazıyorum, çünkü
  /// bu sayılar kullanıcıya ve sponsora gösterilecek):
  ///
  /// - **Plastik:** rPET üretimi 0,45 kg CO₂e/kg, birincil PET 2,15 —
  ///   aradaki fark ton başına ~1.700 kg tasarruf. Tipik 0,5 L pet şişe
  ///   ~20 g ⇒ 0,020 × 1,7 ≈ 35 g.
  /// - **Kağıt:** geri dönüşüm ton başına ~700 kg CO₂e tasarruf sağlıyor
  ///   (yaygın kabul edilen aralık 0,7–1,0 ton). Kutudaki tipik kağıt
  ///   parçası ~30 g ⇒ 0,030 × 0,7 ≈ 20 g.
  /// - **Cam:** eritme yine enerji istediği için tasarruf daha düşük,
  ///   ton başına ~300 kg. Tipik cam şişe ~300 g ⇒ 0,3 × 0,3 ≈ 90 g.
  ///
  /// Bunlar TAHMİNİ değerler; parça ağırlığı varsayımına dayanıyor.
  /// Daha kesin veri bulunursa tek yerden güncellenebilir.
  double get co2GramPerItem => switch (this) {
        WasteType.plastik => 35,
        WasteType.kagit => 20,
        WasteType.cam => 90,
      };

  /// Firestore'da ve ESP32 firmware'inde kullanılacak sabit metin karşılığı.
  /// enum.name kullanıyoruz (ör. "plastik") — okunaklı ve stabil.
  String get id => name;

  /// Firestore'dan okunan metni geri WasteType'a çevirir.
  static WasteType fromId(String id) {
    return WasteType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => WasteType.plastik,
    );
  }
}
