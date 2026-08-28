import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_providers.dart';

/// Bu ayın sıralaması. Ödül ilk üç kişiye verildiği için podyum
/// ekranın en üstünde ve en dikkat çeken öğesi.
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(leaderboardProvider);
    final benimUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıralama'),
        centerTitle: false,
      ),
      body: liste.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'Bu ay sıralama boş',
              message:
                  'Bu ay henüz kimse atık atmadı. İlk atığını atarsan '
                  'sıralamanın başında sen olursun.',
            );
          }

          final ilkUc = entries.take(3).toList();
          final digerleri = entries.skip(3).toList();
          final benimSatirim = benimUid == null
              ? null
              : entries.where((e) => e.uid == benimUid).firstOrNull;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const _AyBilgisi(),
                    const SizedBox(height: 20),
                    _Podyum(ilkUc: ilkUc, benimUid: benimUid),
                    const SizedBox(height: 28),
                    if (digerleri.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          'DİĞER KATILIMCILAR',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final entry in digerleri)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SiraSatiri(
                            entry: entry,
                            benMiyim: entry.uid == benimUid,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              // Kullanıcı listede aşağılardaysa ya da hiç yoksa, kendi
              // durumunu görmek için kaydırmak zorunda kalmasın.
              _BenimDurumum(satir: benimSatirim),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Sıralama yüklenemedi:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

/// Hangi ay olduğu ve ayın bitmesine kaç gün kaldığı — sıralama her ay
/// sıfırlandığı için kullanıcı aciliyeti hissetmeli.
class _AyBilgisi extends StatelessWidget {
  const _AyBilgisi();

  static const _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  @override
  Widget build(BuildContext context) {
    final simdi = DateTime.now();
    // Bir sonraki ayın 0. günü = bu ayın son günü.
    final ayinSonGunu = DateTime(simdi.year, simdi.month + 1, 0).day;
    final kalanGun = ayinSonGunu - simdi.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_aylar[simdi.month - 1]} ayı sıralaması',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  kalanGun > 0
                      ? 'Ayın bitmesine $kalanGun gün — ilk 3 ödül kazanır'
                      : 'Bugün ayın son günü — ilk 3 ödül kazanır',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// İlk üç kişi: ortada birinci ve en yüksek basamak.
class _Podyum extends StatelessWidget {
  const _Podyum({required this.ilkUc, required this.benimUid});
  final List<LeaderboardEntry> ilkUc;
  final String? benimUid;

  @override
  Widget build(BuildContext context) {
    // Görsel sıra: 2. sol, 1. orta, 3. sağ. Listede olmayan sıra boş kalır.
    LeaderboardEntry? sira(int n) =>
        ilkUc.where((e) => e.rank == n).firstOrNull;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodyumSutunu(entry: sira(2), rank: 2, yukseklik: 82, benimUid: benimUid)),
        const SizedBox(width: 10),
        Expanded(child: _PodyumSutunu(entry: sira(1), rank: 1, yukseklik: 112, benimUid: benimUid)),
        const SizedBox(width: 10),
        Expanded(child: _PodyumSutunu(entry: sira(3), rank: 3, yukseklik: 64, benimUid: benimUid)),
      ],
    );
  }
}

class _PodyumSutunu extends StatelessWidget {
  const _PodyumSutunu({
    required this.entry,
    required this.rank,
    required this.yukseklik,
    required this.benimUid,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double yukseklik;
  final String? benimUid;

  // Altın / gümüş / bronz.
  static const _renkler = <int, (Color, Color)>{
    1: (Color(0xFFFFD700), Color(0xFFB8860B)),
    2: (Color(0xFFC0C0C0), Color(0xFF8E8E8E)),
    3: (Color(0xFFCD7F32), Color(0xFF8B4513)),
  };

  @override
  Widget build(BuildContext context) {
    final (acik, koyu) = _renkler[rank]!;
    final benMiyim = entry != null && entry!.uid == benimUid;
    final harf = entry == null
        ? '—'
        : (entry!.gizliAd.isNotEmpty ? entry!.gizliAd[0].toUpperCase() : '?');

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1)
          Icon(
            Icons.workspace_premium_rounded,
            color: entry == null ? Colors.transparent : acik,
            size: 26,
          ),
        const SizedBox(height: 4),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: entry == null
                  ? [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ]
                  : [acik, koyu],
            ),
            border: benMiyim
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                : null,
          ),
          child: Center(
            child: Text(
              harf,
              style: TextStyle(
                color: entry == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry == null ? 'Boş' : entry!.gizliAd,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: benMiyim ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry == null ? '—' : '${entry!.points}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: entry == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : koyu,
          ),
        ),
        const SizedBox(height: 8),
        // Basamak: yüksekliği sırayı görselleştiriyor.
        Container(
          height: yukseklik,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                acik.withValues(alpha: entry == null ? 0.15 : 0.55),
                acik.withValues(alpha: entry == null ? 0.05 : 0.2),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: koyu.withValues(alpha: entry == null ? 0.3 : 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 4. sıradan itibaren kullanılan sade satır.
class _SiraSatiri extends StatelessWidget {
  const _SiraSatiri({required this.entry, required this.benMiyim});
  final LeaderboardEntry entry;
  final bool benMiyim;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: benMiyim
            ? tema.colorScheme.primary.withValues(alpha: 0.12)
            : tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: benMiyim
            ? Border.all(color: tema.colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benMiyim ? '${entry.gizliAd}  (sen)' : entry.gizliAd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: benMiyim ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${entry.points}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: tema.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ekranın altına sabitlenen kendi durumu.
class _BenimDurumum extends StatelessWidget {
  const _BenimDurumum({required this.satir});
  final LeaderboardEntry? satir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(top: BorderSide(color: tema.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: satir == null
            // Kullanıcı bu ay hiç puan kazanmamışsa listede yoktur.
            ? Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: tema.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bu ay henüz puan kazanmadın — atık atarak sıralamaya gir.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Text(
                    'Senin sıran',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${satir!.rank}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${satir!.points} puan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
