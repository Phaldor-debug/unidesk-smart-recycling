import 'package:firebase_auth/firebase_auth.dart';

/// Uygulama içinde fırlatılan, doğrudan ekranda gösterilebilecek Türkçe
/// mesajlı hata. Firebase'in İngilizce hata kodlarını burada çeviriyoruz;
/// böylece presentation katmanı hiç Firebase hata koduyla uğraşmaz.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;

  /// Firebase Auth'un fırlattığı hatayı okunabilir mesaja çevirir.
  /// Yeni bir kod ile karşılaşırsak (ör. 'too-many-requests') buraya eklenir.
  factory AppException.fromFirebaseAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AppException('E-posta adresi geçersiz.');
      case 'user-not-found':
        return const AppException('Bu e-posta ile kayıtlı bir kullanıcı yok.');
      case 'wrong-password':
      case 'invalid-credential':
        return const AppException('E-posta veya şifre hatalı.');
      case 'email-already-in-use':
        return const AppException('Bu e-posta zaten kayıtlı.');
      case 'weak-password':
        return const AppException('Şifre çok zayıf, en az 6 karakter olmalı.');
      case 'network-request-failed':
        return const AppException('İnternet bağlantısı yok.');
      default:
        return AppException('Bir hata oluştu: ${e.message}');
    }
  }
}
