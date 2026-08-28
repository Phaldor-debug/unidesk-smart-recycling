import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/watch_current_user.dart';
import 'auth_providers.dart';
import '../../domain/entities/app_user.dart';

// --- Bağımlılık zinciri: her katman bir öncekini provider ile alır ---
// datasource -> repository -> usecase -> controller
// Bu zincirin faydası: bir testte authRepositoryProvider'ı override edip
// sahte (mock) bir repository verebiliriz, gerçek Firebase'e hiç dokunmadan
// controller'ı test edebiliriz.

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final signUpProvider = Provider((ref) => SignUp(ref.watch(authRepositoryProvider)));
final signInProvider = Provider((ref) => SignIn(ref.watch(authRepositoryProvider)));
final signOutProvider = Provider((ref) => SignOut(ref.watch(authRepositoryProvider)));
final sendPasswordResetProvider =
    Provider((ref) => SendPasswordReset(ref.watch(authRepositoryProvider)));
final watchCurrentUserProvider =
    Provider((ref) => WatchCurrentUser(ref.watch(authRepositoryProvider)));

/// Giriş yapmış kullanıcının profil bilgisi (ad, e-posta, puan), canlı.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(watchCurrentUserProvider).call(user.uid);
});

/// Login/Register ekranlarının kullanacağı controller.
///
/// `AsyncNotifier<void>`: state'i `AsyncValue<void>` tipinde tutar — yani
/// otomatik olarak "yükleniyor / başarılı / hatalı" durumlarını temsil eder.
/// Ekranlar bu state'i izleyip loading çemberi veya hata mesajı gösterir,
/// biz elle bir "isLoading" bool'u falan tutmak zorunda kalmayız.
class AuthController extends AsyncNotifier<void> {
  @override
  void build() {
    // Controller ilk oluşturulduğunda çalışır. Başlangıçta yapılacak
    // bir şey yok, state otomatik olarak AsyncData(null) olur.
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    // AsyncValue.guard: içindeki kodu çalıştırır; bir hata (AppException)
    // fırlarsa yakalayıp otomatik olarak AsyncError'a çevirir. Elle
    // try/catch yazmamıza gerek kalmaz.
    state = await AsyncValue.guard(() async {
      await ref.read(signUpProvider).call(
            email: email,
            password: password,
            displayName: displayName,
          );
    });
  }

  /// Şifre sıfırlama e-postası gönderir. Sonuç ekranda SnackBar ile
  /// bildirilir; state akışı diğer işlemlerle aynı (loading/data/error).
  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(sendPasswordResetProvider).call(email),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(signInProvider).call(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(signOutProvider).call());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
