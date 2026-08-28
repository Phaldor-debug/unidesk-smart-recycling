class AppConstants {
  AppConstants._();

  /// GEÇİCİ: gerçek kutu QR kodunu okutup binId'yi oradan alana kadar
  /// tek bir sabit kutu id'si kullanıyoruz. QR tarama eklenince bu sabit
  /// yerine taranan değer kullanılacak, başka hiçbir yer değişmeyecek.
  static const String demoBinId = 'demo-bin-01';

  /// Puan harcayarak ödül kodu alma sistemi arayüzde görünsün mü?
  ///
  /// Şu an KAPALI. Ödüllendirme, puan harcamaya değil "ayın ilk 3'ü"
  /// sıralamasına dayanıyor — yemekhane entegrasyonu operasyonel olarak
  /// zor olduğu için bu yön seçildi.
  ///
  /// Sistemin kendisi (ödül kataloğu, kod üretme, yemekhane doğrulama,
  /// güvenlik kuralları, veritabanı) BOZULMADAN duruyor; sadece arayüzden
  /// gizlendi. `true` yapmak sekmeyi ve menü girişlerini geri getirir.
  static const bool odulSistemiAcik = false;

  /// Kayıt olabilecek e-posta uzantıları (öğrenci doğrulaması).
  ///
  /// BOŞ bırakılırsa kontrol yapılmaz, herkes kayıt olabilir.
  /// Okulun uzantısını buraya eklediğin an, sadece o uzantıya sahip
  /// e-postalar kayıt olabilir — ör: ['ogr.universite.edu.tr'].
  /// Tek yerden değiştirilebilsin diye burada tutuluyor.
  static const List<String> izinliEpostaUzantilari = <String>[];

  /// Verilen e-posta kayıt için uygun mu? Liste boşsa herkese açıktır.
  static bool epostaUygunMu(String email) {
    if (izinliEpostaUzantilari.isEmpty) return true;
    final kucuk = email.toLowerCase().trim();
    return izinliEpostaUzantilari.any((uzanti) => kucuk.endsWith('@$uzanti'));
  }

  /// Realtime Database'in bölgesi Firestore'dan farklı olabildiği için
  /// (bizde europe-west1) adres firebase_options.dart'ta otomatik gelmez —
  /// Firebase Console'da RTDB'yi oluşturunca verilen tam adres burada sabit.
  static const String rtdbUrl =
      'https://unidesk-geri-donusum-default-rtdb.europe-west1.firebasedatabase.app';
}
