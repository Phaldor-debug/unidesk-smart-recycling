import '../entities/app_user.dart';

/// Auth ile ilgili "ne yapılabilir" sözleşmesi. İçeride Firebase'e dair
/// TEK bir kelime geçmez — data katmanının uyacağı bir kontrattır.
/// Bu sayede domain ve presentation katmanları Firebase'i hiç bilmez.
abstract class AuthRepository {
  Future<AppUser> signUp({required String email, required String password});
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();
}
