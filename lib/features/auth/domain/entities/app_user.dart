/// Uygulamanın kendi kullanıcı temsili. Firebase'in User sınıfına değil
/// buna bağımlı oluruz — yarın Firebase'i değiştirsek bile domain ve
/// presentation katmanları hiç değişmez, sadece data katmanı değişir.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.points,
  });

  final String uid;
  final String email;
  final int points;
}
