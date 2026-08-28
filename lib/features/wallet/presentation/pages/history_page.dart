import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../providers/wallet_providers.dart';

/// Kullanıcının puan geçmişi: attığı atıklardan kazandıkları ve
/// kullandığı ödüllerden harcadıkları, tarihe göre gruplanmış tek listede.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Puan Geçmişi')),
      body: transactions.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Henüz bir hareket yok',
              message:
                  'Atık attıkça kazandığın, ödül kullandıkça harcadığın '
                  'puanlar burada tarih sırasıyla listelenecek.',
            );
          }

          // Ay içindeki toplamları özet olarak en üstte gösteriyoruz:
          // kullanıcı tek tek satırları toplamak zorunda kalmasın.
          final simdi = DateTime.now();
          var ayKazanc = 0;
          var ayHarcama = 0;
          for (final islem in list) {
            final t = islem.date;
            if (t == null || t.year != simdi.year || t.month != simdi.month) continue;
            if (islem.kind == TransactionKind.earned) {
              ayKazanc += islem.points;
            } else {
              ayHarcama += islem.points;
            }
          }

          final gruplar = _tariheGoreGrupla(list);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            // +1: en üstteki aylık özet kartı.
            itemCount: gruplar.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AylikOzet(kazanc: ayKazanc, harcama: ayHarcama);
              }
              final grup = gruplar[index - 1];
              return _GunGrubu(grup: grup);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Geçmiş yüklenemedi:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  /// İşlemleri güne göre gruplar. Liste zaten yeniden eskiye sıralı
  /// geldiği için gruplar da o sırayı korur.
  static List<_Grup> _tariheGoreGrupla(List<WalletTransaction> list) {
    final gruplar = <_Grup>[];
    String? sonEtiket;

    for (final islem in list) {
      final etiket = _gunEtiketi(islem.date);
      if (etiket != sonEtiket) {
        gruplar.add(_Grup(etiket: etiket, islemler: [islem]));
        sonEtiket = etiket;
      } else {
        gruplar.last.islemler.add(islem);
      }
    }
    return gruplar;
  }

  static const _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  static String _gunEtiketi(DateTime? date) {
    if (date == null) return 'Az önce';

    final simdi = DateTime.now();
    final bugun = DateTime(simdi.year, simdi.month, simdi.day);
    final gun = DateTime(date.year, date.month, date.day);
    final fark = bugun.difference(gun).inDays;

    if (fark == 0) return 'Bugün';
    if (fark == 1) return 'Dün';
    if (date.year == simdi.year) return '${date.day} ${_aylar[date.month - 1]}';
    return '${date.day} ${_aylar[date.month - 1]} ${date.year}';
  }
}

class _Grup {
  _Grup({required this.etiket, required this.islemler});
  final String etiket;
  final List<WalletTransaction> islemler;
}

/// Bu ayın kazanç ve harcama toplamı.
class _AylikOzet extends StatelessWidget {
  const _AylikOzet({required this.kazanc, required this.harcama});
  final int kazanc;
  final int harcama;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OzetSutun(
              etiket: 'Bu ay kazanılan',
              deger: '+$kazanc',
              renk: AppColors.green,
              icon: Icons.trending_up_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _OzetSutun(
              etiket: 'Bu ay harcanan',
              deger: '−$harcama',
              renk: AppColors.gold,
              icon: Icons.redeem_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _OzetSutun extends StatelessWidget {
  const _OzetSutun({
    required this.etiket,
    required this.deger,
    required this.renk,
    required this.icon,
  });

  final String etiket;
  final String deger;
  final Color renk;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: renk, size: 20),
        const SizedBox(height: 6),
        Text(
          deger,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: renk),
        ),
        const SizedBox(height: 2),
        Text(
          etiket,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GunGrubu extends StatelessWidget {
  const _GunGrubu({required this.grup});
  final _Grup grup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            grup.etiket.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final islem in grup.islemler)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IslemSatiri(item: islem),
          ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _IslemSatiri extends StatelessWidget {
  const _IslemSatiri({required this.item});
  final WalletTransaction item;

  @override
  Widget build(BuildContext context) {
    final kazanc = item.kind == TransactionKind.earned;
    // Kazanç yeşil (+), harcama altın (−) — uygulamanın iki marka rengi,
    // yönü renkten de anlaşılsın diye.
    final renk = kazanc ? AppColors.green : AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              kazanc ? Icons.recycling_rounded : Icons.redeem_rounded,
              color: renk,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  _saat(item.date),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${kazanc ? '+' : '−'}${item.points}',
            style: TextStyle(
              color: renk,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  /// Gün bilgisi zaten grup başlığında olduğu için satırda sadece saat
  /// gösteriyoruz — tekrar olmasın.
  String _saat(DateTime? date) {
    if (date == null) return 'Az önce';
    String iki(int n) => n.toString().padLeft(2, '0');
    return '${iki(date.hour)}:${iki(date.minute)}';
  }
}
