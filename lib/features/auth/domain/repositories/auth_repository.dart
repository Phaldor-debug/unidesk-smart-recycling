import '../entities/app_user.dart';

/// Auth ile ilgili "ne yapılabilir" sözleşmesi. İçeride Firebase'e dair
/// TEK bir kelime geçmez — data katmanının uyacağı bir kontrattır.
/// Bu sayede domain ve presentation katmanları Firebase'i hiç bilmez.
abstract class AuthRepository {
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();

  /// Kullanıcının profil bilgisini (ad, e-posta, puan) CANLI izler.
  /// Profil ekranı ve ana sayfadaki karşılama bunu kullanır.
  Stream<AppUser> watchCurrentUser(String uid);

  /// Giriş yapmış kullanıcıya e-posta doğrulama bağlantısı gönderir.
  /// Öğrenci doğrulamasının temeli: kullanıcı okul e-postasına gelen
  /// bağlantıya tıklamadan ödül kullanamaz.
  Future<void> sendEmailVerification();

  /// Doğrulama durumunu sunucudan TAZELER ve sonucu döner.
  /// Kullanıcı e-postadaki bağlantıya tıkladıktan sonra uygulamanın
  /// bunu fark etmesi için gerekli (Firebase yerel kopyayı kendiliğinden
  /// güncellemiyor).
  Future<bool> refreshEmailVerified();

  /// Şifre sıfırlama bağlantısını e-posta ile gönderir.
  /// Bu olmadan şifresini unutan kullanıcı hesabına bir daha giremiyordu.
  Future<void> sendPasswordResetEmail(String email);
}
