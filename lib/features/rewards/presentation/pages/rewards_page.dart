import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/big_action_card.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../../wallet/presentation/widgets/points_balance_card.dart';
import '../providers/redeem_controller.dart';
import '../providers/rewards_providers.dart';
import 'my_codes_page.dart';
import 'redemption_code_page.dart';
import 'staff_verify_page.dart';

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(pointsBalanceProvider);
    final rewards = ref.watch(rewardsListProvider);
    final redeemState = ref.watch(redeemControllerProvider);
    final myCodes = ref.watch(myActiveRedemptionsProvider);

    // Talep başarıyla sonuçlandığında (yükleniyordan veriye geçtiğinde ve
    // bir kod üretildiğinde) kod ekranına geç.
    ref.listen(redeemControllerProvider, (previous, next) {
      final redemption = next.value;
      if (previous is AsyncLoading && next is AsyncData && redemption != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RedemptionCodePage(redemption: redemption)),
        );
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödüller'),
        actions: [
          // Kullanılmamış kodlar: sayı varsa rozetle belirtiliyor ki
          // kullanıcı elinde bekleyen bir hakkı olduğunu fark etsin.
          IconButton(
            icon: Badge(
              isLabelVisible: (myCodes.value?.isNotEmpty ?? false),
              label: Text('${myCodes.value?.length ?? 0}'),
              child: const Icon(Icons.confirmation_number_outlined),
            ),
            tooltip: 'Kodlarım',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyCodesPage()),
              );
            },
          ),
          // GEÇİCİ: gerçek uygulamada bu, öğrencinin göremeyeceği ayrı bir
          // yemekhane personeli girişi/uygulaması olurdu. Şimdilik demo
          // için aynı uygulama içinde erişilebilir bıraktık.
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Yemekhane Paneli (personel)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StaffVerifyPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // Puan bakiyesi kartı: hem ana sayfada hem burada AYNI bileşen —
          // marka tutarlılığı ve tek yerden bakım.
          const PointsBalanceCard(),
          balance.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Hata: $error'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: rewards.when(
              data: (list) {
                if (list.isEmpty) {
                  // Firestore'daki `rewards` koleksiyonu boş — henüz hiç
                  // ödül eklenmemiş. Firebase Console'dan eklenebilir.
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Henüz ödül eklenmedi.\n'
                      'Firebase Console → Firestore → "rewards" koleksiyonuna\n'
                      'title (metin) + costPoints (sayı) + active (true) alanlarıyla\n'
                      'bir belge ekleyebilirsin.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final currentPoints = balance.value?.points ?? 0;
                return Column(
                  children: list.map((reward) {
                    final canAfford = currentPoints >= reward.costPoints;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: BigActionCard(
                        color: AppColors.gold,
                        icon: Icons.redeem_rounded,
                        title: reward.title,
                        subtitle: canAfford
                            ? '${reward.costPoints} puan — kullanılabilir'
                            : '${reward.costPoints} puan gerekiyor',
                        enabled: canAfford && !redeemState.isLoading,
                        onTap: () => ref.read(redeemControllerProvider.notifier).redeem(reward),
                        trailing: redeemState.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Hata: $error'),
            ),
          ),
        ],
      ),
    );
  }
}
