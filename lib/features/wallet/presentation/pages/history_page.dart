import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../providers/wallet_providers.dart';

/// Kullanıcının puan geçmişi: attığı atıklardan kazandıkları ve
/// kullandığı ödüllerden harcadıkları, tarihe göre tek listede.
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
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _TransactionTile(item: list[index]),
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
              Icons.history_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz bir hareket yok',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Atık attıkça ve ödül kullandıkça\nburada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});
  final WalletTransaction item;

  @override
  Widget build(BuildContext context) {
    final kazanc = item.kind == TransactionKind.earned;
    // Kazanç yeşil (+), harcama altın (−) — uygulamanın iki marka rengi,
    // yönü renkten de anlaşılsın diye.
    final renk = kazanc ? AppColors.green : AppColors.gold;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                kazanc ? Icons.recycling_rounded : Icons.redeem_rounded,
                color: renk,
              ),
            ),
            const SizedBox(width: 14),
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
                    _tarihMetni(item.date),
                    style: TextStyle(
                      fontSize: 13,
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
      ),
    );
  }

  /// Tarihi kısa ve okunur biçimde yazar. Ayrı bir tarih paketi (intl)
  /// eklememek için elle biçimlendiriyoruz — tek yerde kullanılıyor.
  String _tarihMetni(DateTime? date) {
    if (date == null) return 'Az önce';
    String iki(int n) => n.toString().padLeft(2, '0');
    return '${iki(date.day)}.${iki(date.month)}.${date.year}  ${iki(date.hour)}:${iki(date.minute)}';
  }
}
