class AppConstants {
  AppConstants._();

  /// GEÇİCİ: gerçek kutu QR kodunu okutup binId'yi oradan alana kadar
  /// tek bir sabit kutu id'si kullanıyoruz. QR tarama eklenince bu sabit
  /// yerine taranan değer kullanılacak, başka hiçbir yer değişmeyecek.
  static const String demoBinId = 'demo-bin-01';

  /// Realtime Database'in bölgesi Firestore'dan farklı olabildiği için
  /// (bizde europe-west1) adres firebase_options.dart'ta otomatik gelmez —
  /// Firebase Console'da RTDB'yi oluşturunca verilen tam adres burada sabit.
  static const String rtdbUrl =
      'https://unidesk-geri-donusum-default-rtdb.europe-west1.firebasedatabase.app';
}
