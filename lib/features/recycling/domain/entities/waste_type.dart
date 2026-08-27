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
