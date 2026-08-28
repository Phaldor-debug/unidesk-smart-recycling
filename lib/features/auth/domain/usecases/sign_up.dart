import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// "Kayıt ol" iş kuralı. Şimdilik sadece repository'yi çağırıyor,
/// ama ileride "üniversite e-postası mı" gibi kontroller domain'i
/// (yani burayı) etkiler, data/presentation'a dokunmaz.
class SignUp {
  const SignUp(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
