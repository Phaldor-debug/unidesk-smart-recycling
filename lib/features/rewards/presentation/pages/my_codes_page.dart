import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/redemption.dart';
import '../providers/rewards_providers.dart';

/// Kullanıcının henüz kullanmadığı kodları listeler.
///
/// Bu ekran olmadan, kod üretildikten sonra RedemptionCodePage kapatılınca
/// kod bir daha görülemiyordu — puan harcanmış ama hak kullanılamaz
/// durumda kalıyordu. Ödül sisteminin çalışması için bu ekran şart.
class MyCodesPage extends ConsumerWidget {
  const MyCodesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codes = ref.watch(myActiveRedemptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kodlarım')),
      body: codes.when(
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _CodeCard(redemption: list[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Kodlar yüklenemedi:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Kullanılmamış kodun yok',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Ödüller ekranından puanını harcayarak\nyeni bir kod alabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir kodun kartı: ödül adı + yemekhanede okunacak büyük kod.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.redemption});
  final Redemption redemption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gold, Color(0xFFE6A400)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.redeem_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  redemption.rewardTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Kodu büyük ve boşluklu göster — yemekhanede uzaktan
          // okunması kolay olsun diye.
          Text(
            redemption.code.split('').join(' '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Yemekhanede bu kodu göster',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
