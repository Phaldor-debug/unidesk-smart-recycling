import '../repositories/auth_repository.dart';

/// "Çıkış yap" iş kuralı.
class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
