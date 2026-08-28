import '../repositories/auth_repository.dart';

/// "Şifremi unuttum" iş kuralı: e-postaya sıfırlama bağlantısı gönderir.
class SendPasswordReset {
  const SendPasswordReset(this._repository);
  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendPasswordResetEmail(email);
}
