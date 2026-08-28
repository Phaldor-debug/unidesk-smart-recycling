import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/rewards_remote_datasource.dart';
import '../../data/repositories/rewards_repository_impl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';
import '../../domain/repositories/rewards_repository.dart';
import '../../domain/usecases/find_redemption_by_code.dart';
import '../../domain/usecases/mark_redemption_used.dart';
import '../../domain/usecases/redeem_reward.dart';
import '../../domain/usecases/watch_my_active_redemptions.dart';
import '../../domain/usecases/watch_rewards.dart';

final rewardsRemoteDataSourceProvider = Provider<RewardsRemoteDataSource>((ref) {
  return RewardsRemoteDataSource(ref.watch(firestoreProvider));
});

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepositoryImpl(ref.watch(rewardsRemoteDataSourceProvider));
});

final redeemRewardProvider = Provider(
  (ref) => RedeemReward(ref.watch(rewardsRepositoryProvider)),
);

final findRedemptionByCodeProvider = Provider(
  (ref) => FindRedemptionByCode(ref.watch(rewardsRepositoryProvider)),
);

final markRedemptionUsedProvider = Provider(
  (ref) => MarkRedemptionUsed(ref.watch(rewardsRepositoryProvider)),
);

/// Firestore'daki `rewards` koleksiyonunu (aktif olanları) canlı yayınlar.
/// Firebase Console'dan yeni bir belge eklendiği an, bu liste — ve dolayısıyla
/// RewardsPage — uygulamayı yeniden başlatmadan güncellenir.
final rewardsListProvider = StreamProvider<List<Reward>>((ref) {
  return ref.watch(watchRewardsProvider).call();
});

final watchRewardsProvider = Provider(
  (ref) => WatchRewards(ref.watch(rewardsRepositoryProvider)),
);

final watchMyActiveRedemptionsProvider = Provider(
  (ref) => WatchMyActiveRedemptions(ref.watch(rewardsRepositoryProvider)),
);

/// Kullanıcının elindeki kullanılmamış kodlar. Kod ekranı kapatılsa bile
/// buradan tekrar görülebilir — ödül sisteminin kullanılabilir olması için
/// bu şart.
final myActiveRedemptionsProvider = StreamProvider<List<Redemption>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(watchMyActiveRedemptionsProvider).call(user.uid);
});
