import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../providers/leaderboard_providers.dart';

/// Global sıralama tablosu. İlk üç altın/gümüş/bronz madalya ile,
/// gerisi düz sıra numarasıyla listelenir.
class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liste = ref.watch(leaderboardProvider);
    final benimUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Bu Ayın Sıralaması')),
      body: liste.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Sıralama henüz oluşmadı.\nAtık atan ilk kişi sen ol!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            // +1: en üstteki bilgi satırı için.
            itemCount: entries.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) return const _BilgiSatiri();
              final entry = entries[index - 1];
              return _LeaderboardTile(
                entry: entry,
                benMiyim: entry.uid == benimUid,
              );
            },
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

/// Sıralamanın neye göre olduğunu açıklar — kullanıcı "ödül alırsam
/// sıram düşer mi?" diye tereddüt etmesin.
class _BilgiSatiri extends StatelessWidget {
  const _BilgiSatiri();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sıralama bu ay kazandığın puana göre. Ödül kullanmak sıranı düşürmez.',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.benMiyim});
  final LeaderboardEntry entry;
  final bool benMiyim;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // Kendi satırını vurguluyoruz ki kullanıcı uzun listede
        // kendini hemen bulabilsin.
        color: benMiyim
            ? tema.colorScheme.primary.withValues(alpha: 0.12)
            : tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: benMiyim
            ? Border.all(color: tema.colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              benMiyim ? '${entry.gizliAd}  (sen)' : entry.gizliAd,
              style: TextStyle(
                fontWeight: benMiyim ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.points}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: tema.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text('puan', style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// İlk üç için madalya, sonrası için düz numara.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  // Altın / gümüş / bronz.
  static const _madalyaRenkleri = <int, (Color, Color)>{
    1: (Color(0xFFFFD700), Color(0xFFB8860B)),
    2: (Color(0xFFC0C0C0), Color(0xFF808080)),
    3: (Color(0xFFCD7F32), Color(0xFF8B4513)),
  };

  @override
  Widget build(BuildContext context) {
    final madalya = _madalyaRenkleri[rank];

    if (madalya == null) {
      // 4. sıradan itibaren: sade numara.
      return SizedBox(
        width: 40,
        child: Text(
          '$rank',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final (acikRenk, koyuRenk) = madalya;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [acikRenk, koyuRenk],
        ),
        boxShadow: [
          BoxShadow(
            color: acikRenk.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
