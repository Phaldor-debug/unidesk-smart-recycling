import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/badge_stats.dart';
import '../providers/badge_providers.dart';

/// Kullanıcının kazandığı ve kazanmadığı rozetler.
///
/// Kilitli rozetler de gösteriliyor (soluk, ilerleme çubuğuyla) —
/// "sıradaki hedef ne" bilgisi rozet sisteminin asıl motive edici kısmı.
class BadgesPage extends ConsumerWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durum = ref.watch(badgeStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rozetlerim')),
      body: durum.when(
        data: (veri) {
          final kazanilan = veri.kazanilanlar.toSet();
          final gruplar = BadgeGroup.values;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _Ozet(
                kazanilanSayi: kazanilan.length,
                toplamSayi: tumRozetler.length,
                stats: veri.stats,
              ),
              const SizedBox(height: 24),
              for (final grup in gruplar) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    grup.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final rozet in tumRozetler.where((r) => r.group == grup))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RozetKarti(
                      rozet: rozet,
                      kazanildi: kazanilan.contains(rozet.id),
                      stats: veri.stats,
                    ),
                  ),
                const SizedBox(height: 18),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Rozetler yüklenemedi:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _Ozet extends StatelessWidget {
  const _Ozet({
    required this.kazanilanSayi,
    required this.toplamSayi,
    required this.stats,
  });

  final int kazanilanSayi;
  final int toplamSayi;
  final BadgeStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            '$kazanilanSayi / $toplamSayi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text('rozet kazandın', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌍', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  // Projenin asıl amacı bu: kaç puan değil, ne kadar
                  // salım önlendi.
                  '${stats.co2Kg.toStringAsFixed(2)} kg CO₂ salımı önledin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RozetKarti extends StatelessWidget {
  const _RozetKarti({
    required this.rozet,
    required this.kazanildi,
    required this.stats,
  });

  final Achievement rozet;
  final bool kazanildi;
  final BadgeStats stats;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oran = rozet.ilerlemeOrani(stats);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kazanildi
            ? AppColors.gold.withValues(alpha: 0.12)
            : tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: kazanildi
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kilitli rozetler soluk: kazanılanla arasındaki fark tek
          // bakışta anlaşılsın.
          Opacity(
            opacity: kazanildi ? 1 : 0.35,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tema.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Text(rozet.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rozet.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: kazanildi ? null : tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '+${rozet.bonusPoints}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kazanildi ? AppColors.gold : tema.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rozet.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                // İlerleme çubuğu yalnızca ölçülebilir hedefi olan
                // kilitli rozetlerde anlamlı.
                if (!kazanildi && rozet.ilerleme != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: oran,
                      minHeight: 5,
                      backgroundColor: tema.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
