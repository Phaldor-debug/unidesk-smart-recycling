/// Uygulamanın kendi kullanıcı temsili. Firebase'in User sınıfına değil
/// buna bağımlı oluruz — yarın Firebase'i değiştirsek bile domain ve
/// presentation katmanları hiç değişmez, sadece data katmanı değişir.
///
/// E-POSTA BİLEREK BURADA YOK: sıralama tablosu için kullanıcı kayıtları
/// herkese okunabilir olmak zorunda, e-posta da orada tutulsaydı bütün
/// öğrencilerin adresi birbirine açılırdı. E-posta zaten Firebase Auth'ta
/// var, oradan okunuyor (authStateProvider).
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.points,
  });

  final String uid;

  /// Öğrencinin adı soyadı. Yemekhanede kodu doğrulayan personelin
  /// "bu hak kimin" sorusuna cevap verebilmesi ve sıralama tablosu için.
  final String displayName;

  final int points;
}
