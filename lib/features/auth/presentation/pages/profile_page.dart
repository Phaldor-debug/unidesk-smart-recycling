import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';
import '../../../rewards/presentation/pages/my_codes_page.dart';
import '../../../rewards/presentation/providers/rewards_providers.dart';
import '../../../wallet/presentation/pages/history_page.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_providers.dart';
import '../providers/email_verification_provider.dart';

/// Kullanıcının kendi bilgilerini gördüğü ekran.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    // E-posta artık Firestore'da tutulmuyor (sıralama tablosu herkese
    // açık olduğu için) — doğrudan Firebase Auth'tan okuyoruz.
    final authUser = ref.watch(authStateProvider).value;
    final dogrulandi = ref.watch(emailVerificationProvider).value ?? false;
    final kodSayisi = ref.watch(myActiveRedemptionsProvider).value?.length ?? 0;
    final siralama = ref.watch(leaderboardProvider).value;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          final gorunenAd = user.displayName.isNotEmpty
              ? user.displayName
              : (authUser?.email?.split('@').first ?? 'Kullanıcı');

          // Kullanıcının sıralamadaki yeri (ilk 50'de değilse null).
          final benimSira = siralama
              ?.where((e) => e.uid == user.uid)
              .map((e) => e.rank)
              .firstOrNull;

          return CustomScrollView(
            slivers: [
              // Renkli, marka kimliğine uygun bir başlık — kaydırınca
              // küçülüp normal bir AppBar'a dönüşüyor.
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfilHeader(
                    ad: gorunenAd,
                    email: authUser?.email ?? '',
                    dogrulandi: dogrulandi,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Üç kutuluk özet: puan, sıra, bekleyen kod.
                      Row(
                        children: [
                          Expanded(
                            child: _StatKutusu(
                              icon: Icons.stars_rounded,
                              renk: AppColors.gold,
                              deger: '${user.points}',
                              etiket: 'Puan',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatKutusu(
                              icon: Icons.leaderboard_rounded,
                              renk: AppColors.green,
                              deger: benimSira != null ? '#$benimSira' : '—',
                              etiket: 'Sıra',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatKutusu(
                              icon: Icons.confirmation_number_outlined,
                              renk: const Color(0xFF7C3AED),
                              deger: '$kodSayisi',
                              etiket: 'Kod',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _MenuKarti(
                        children: [
                          _MenuSatiri(
                            icon: Icons.leaderboard_rounded,
                            baslik: 'Sıralama',
                            altBaslik: 'Global puan sıralamasını gör',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                            ),
                          ),
                          _MenuSatiri(
                            icon: Icons.confirmation_number_outlined,
                            baslik: 'Kodlarım',
                            altBaslik: 'Kullanılmamış ödül kodların',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyCodesPage()),
                            ),
                          ),
                          _MenuSatiri(
                            icon: Icons.history_rounded,
                            baslik: 'Puan geçmişi',
                            altBaslik: 'Kazandıkların ve harcadıkların',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const HistoryPage()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MenuKarti(
                        children: [
                          _MenuSatiri(
                            icon: Icons.lock_reset_rounded,
                            baslik: 'Şifremi değiştir',
                            altBaslik: 'E-postana sıfırlama bağlantısı gönderilir',
                            onTap: () => _sifreSifirla(context, ref, authUser?.email ?? ''),
                          ),
                          _MenuSatiri(
                            icon: Icons.logout_rounded,
                            baslik: 'Çıkış yap',
                            renk: Colors.redAccent,
                            onTap: () =>
                                ref.read(authControllerProvider.notifier).signOut(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
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
    if (email.isEmpty) return;
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

class _ProfilHeader extends StatelessWidget {
  const _ProfilHeader({
    required this.ad,
    required this.email,
    required this.dogrulandi,
  });

  final String ad;
  final String email;
  final bool dogrulandi;

  @override
  Widget build(BuildContext context) {
    final harf = ad.isNotEmpty ? ad[0].toUpperCase() : '?';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, Color(0xFF15803D)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              ),
              child: Center(
                child: Text(
                  harf,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ad,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                // Doğrulanmış hesabı rozetle belirtiyoruz — kullanıcı
                // ödül kullanabilir durumda mı, tek bakışta görsün.
                Icon(
                  dogrulandi ? Icons.verified_rounded : Icons.error_outline_rounded,
                  size: 16,
                  color: dogrulandi ? Colors.white : Colors.orangeAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatKutusu extends StatelessWidget {
  const _StatKutusu({
    required this.icon,
    required this.renk,
    required this.deger,
    required this.etiket,
  });

  final IconData icon;
  final Color renk;
  final String deger;
  final String etiket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 24),
          const SizedBox(height: 6),
          Text(
            deger,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: renk),
          ),
          Text(
            etiket,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuKarti extends StatelessWidget {
  const _MenuKarti({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 60),
          ],
        ],
      ),
    );
  }
}

class _MenuSatiri extends StatelessWidget {
  const _MenuSatiri({
    required this.icon,
    required this.baslik,
    this.altBaslik,
    this.renk,
    required this.onTap,
  });

  final IconData icon;
  final String baslik;
  final String? altBaslik;
  final Color? renk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final efektifRenk = renk ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: efektifRenk),
      title: Text(baslik, style: TextStyle(color: efektifRenk, fontWeight: FontWeight.w600)),
      subtitle: altBaslik != null ? Text(altBaslik!) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
