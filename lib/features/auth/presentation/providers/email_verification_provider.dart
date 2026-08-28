import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'auth_providers.dart';

/// Kullanıcının e-postasını doğrulayıp doğrulamadığını tutar.
///
/// Neden ayrı bir Notifier: Firebase, e-posta doğrulandığında canlı bir
/// bildirim YAYINLAMAZ. Kullanıcı e-postadaki bağlantıya tıkladıktan
/// sonra uygulamanın durumu sunucudan tazelemesi (reload) gerekir —
/// "Doğruladım" butonu bu tazelemeyi tetikler.
class EmailVerificationNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Oturum değişince (giriş/çıkış) bu provider da kendini yeniler.
    final user = ref.watch(authStateProvider).value;
    if (user == null) return false;
    return user.emailVerified;
  }

  /// Sunucudan tazeleyip sonucu döner. Kullanıcı "Doğruladım" dediğinde.
  Future<bool> tazele() async {
    state = const AsyncLoading();
    final sonuc = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).refreshEmailVerified(),
    );
    state = sonuc;
    return sonuc.value ?? false;
  }

  /// Doğrulama bağlantısını tekrar gönderir.
  Future<void> tekrarGonder() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }
}

final emailVerificationProvider =
    AsyncNotifierProvider<EmailVerificationNotifier, bool>(EmailVerificationNotifier.new);
