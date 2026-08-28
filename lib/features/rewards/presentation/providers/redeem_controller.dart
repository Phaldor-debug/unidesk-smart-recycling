import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/email_verification_provider.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';
import 'rewards_providers.dart';

/// RewardsPage'in kullandığı controller. State'i `Redemption?`:
/// null = henüz bir şey talep edilmedi, dolu = son üretilen kod.
class RedeemController extends AsyncNotifier<Redemption?> {
  @override
  Redemption? build() => null; // başlangıç: hiçbir hak talep edilmemiş.

  Future<void> redeem(Reward reward) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return; // AuthGate zaten girişsiz buraya gelmeyi engeller.

    // Öğrenci doğrulaması: e-postasını doğrulamamış hesap ödül kullanamaz.
    // Puan kazanmak serbest, harcamak doğrulama ister — böylece okul
    // dışından biri sisteme yük olmadan ödül alamaz.
    final dogrulandi = ref.read(emailVerificationProvider).value ?? false;
    if (!dogrulandi) {
      state = AsyncError(
        const AppException(
          'Ödül kullanmak için önce e-postanı doğrulaman gerekiyor. '
          'Ana sayfadaki uyarıdan doğrulama bağlantısını gönderebilirsin.',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    // AsyncValue.guard: 'Yetersiz puan' gibi hataları otomatik AsyncError'a çevirir.
    state = await AsyncValue.guard(
      () => ref.read(redeemRewardProvider).call(uid: uid, reward: reward),
    );
  }
}

final redeemControllerProvider = AsyncNotifierProvider<RedeemController, Redemption?>(
  RedeemController.new,
);
