import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/email_verification_provider.dart';

/// E-postasını doğrulamamış kullanıcıya gösterilen uyarı bandı.
/// Doğrulanmışsa hiç görünmez (boş widget döner).
class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durum = ref.watch(emailVerificationProvider);
    final dogrulandi = durum.value ?? false;
    if (dogrulandi) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_outlined, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'E-postanı doğrula',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Puan kazanmaya devam edebilirsin, ancak ödül kazanabilmen için '
            'okul e-postana gönderdiğimiz bağlantıya tıklaman gerekiyor.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Kullanıcı bağlantıya tıkladıktan sonra uygulamanın durumu
              // fark etmesi için sunucudan tazeleme şart.
              FilledButton.tonal(
                onPressed: durum.isLoading
                    ? null
                    : () async {
                        final sonuc =
                            await ref.read(emailVerificationProvider.notifier).tazele();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(sonuc
                                ? 'E-postan doğrulandı, teşekkürler!'
                                : 'Henüz doğrulanmamış. Bağlantıya tıkladıktan sonra tekrar dene.'),
                          ),
                        );
                      },
                child: const Text('Doğruladım'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: durum.isLoading
                    ? null
                    : () async {
                        await ref.read(emailVerificationProvider.notifier).tekrarGonder();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Doğrulama bağlantısı tekrar gönderildi.')),
                        );
                      },
                child: const Text('Tekrar gönder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
