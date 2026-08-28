import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../wallet/presentation/pages/history_page.dart';
import '../providers/auth_controller.dart';

/// Kullanıcının kendi bilgilerini gördüğü ekran: ad, e-posta, güncel puan
/// ve hesap işlemleri (şifre sıfırlama, çıkış).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          // Adı yoksa (bu alan eklenmeden önce kaydolmuş kullanıcılar)
          // e-postanın @ öncesini gösteriyoruz — boş bir kart kalmasın.
          final gorunenAd =
              user.displayName.isNotEmpty ? user.displayName : user.email.split('@').first;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              _Avatar(name: gorunenAd),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  gorunenAd,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 28),
              _InfoTile(
                icon: Icons.stars_rounded,
                color: AppColors.gold,
                title: 'Puan bakiyen',
                value: '${user.points}',
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: const Text('Puan geçmişi'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryPage()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded),
                      title: const Text('Şifremi değiştir'),
                      subtitle: const Text('E-postana sıfırlama bağlantısı gönderilir'),
                      onTap: () => _sifreSifirla(context, ref, user.email),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Çıkış Yap'),
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Profil yüklenemedi:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future<void> _sifreSifirla(BuildContext context, WidgetRef ref, String email) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre sıfırlama'),
        content: Text('$email adresine bir sıfırlama bağlantısı gönderilsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );

    if (onay != true) return;
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);

    // async çağrıdan sonra ekran hâlâ duruyor mu, kontrol et.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sıfırlama bağlantısı gönderildi.')),
    );
  }
}

/// Adın baş harfinden oluşan basit bir avatar — profil fotoğrafı
/// özelliği olmadığı için kimlik hissini bu veriyor.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final harf = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            harf,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
