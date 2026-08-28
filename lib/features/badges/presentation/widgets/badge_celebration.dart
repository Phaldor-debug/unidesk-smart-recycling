import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/badge.dart';
import '../providers/badge_providers.dart';

/// Rozet kazanıldığında kutlama penceresini açan görünmez dinleyici.
///
/// Uygulama iskeletine yerleştiriliyor: rozet hangi ekranda kazanılırsa
/// kazanılsın (atık atma ekranı, arka planda kapanan oturum) kutlama
/// gösterilebilsin diye. Kendisi hiçbir şey çizmez.
class BadgeCelebrationListener extends ConsumerWidget {
  const BadgeCelebrationListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<List<Achievement>>(badgeCheckerProvider, (previous, next) {
      if (next.isEmpty) return;
      // Kutlamayı gösterdikten sonra listeyi temizliyoruz ki aynı rozet
      // için tekrar açılmasın.
      ref.read(badgeCheckerProvider.notifier).temizle();
      _goster(context, next);
    });

    return child;
  }

  Future<void> _goster(BuildContext context, List<Achievement> rozetler) {
    return showDialog<void>(
      context: context,
      builder: (context) => _KutlamaPenceresi(rozetler: rozetler),
    );
  }
}

class _KutlamaPenceresi extends StatelessWidget {
  const _KutlamaPenceresi({required this.rozetler});
  final List<Achievement> rozetler;

  @override
  Widget build(BuildContext context) {
    final toplamBonus = rozetler.fold<int>(0, (t, r) => t + r.bonusPoints);
    final coklu = rozetler.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              coklu ? '🎉' : rozetler.first.emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 14),
            Text(
              coklu ? '${rozetler.length} yeni rozet!' : 'Yeni rozet!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            for (final rozet in rozetler)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(rozet.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rozet.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            rozet.description,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${rozet.bonusPoints}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Toplam +$toplamBonus puan',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Harika!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
