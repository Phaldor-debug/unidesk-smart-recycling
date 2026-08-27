import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wallet_providers.dart';

/// Ana sayfada gösterilecek puan bakiyesi kartı.
class PointsBalanceCard extends ConsumerWidget {
  const PointsBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(pointsBalanceProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Puan Bakiyen', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            // .when: 3 durumu ayrı ayrı ele alıyoruz.
            balance.when(
              data: (value) => Text(
                '${value.points}',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Hata: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
