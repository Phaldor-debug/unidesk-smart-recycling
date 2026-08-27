import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../providers/redeem_controller.dart';
import '../providers/rewards_providers.dart';
import 'redemption_code_page.dart';
import 'staff_verify_page.dart';

class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(pointsBalanceProvider);
    final rewards = ref.watch(rewardsListProvider);
    final redeemState = ref.watch(redeemControllerProvider);

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
        padding: const EdgeInsets.all(16),
        children: [
          balance.when(
            data: (value) => Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Bakiyen: ${value.points} puan',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Hata: $error'),
          ),
          const SizedBox(height: 16),
          rewards.when(
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
                  return Card(
                    child: ListTile(
                      title: Text(reward.title),
                      subtitle: Text('${reward.costPoints} puan'),
                      trailing: FilledButton(
                        // Yetersiz puanda veya bir talep zaten işlenirken buton kapalı.
                        onPressed: (canAfford && !redeemState.isLoading)
                            ? () => ref.read(redeemControllerProvider.notifier).redeem(reward)
                            : null,
                        child: redeemState.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kullan'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Hata: $error'),
          ),
        ],
      ),
    );
  }
}
