import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/big_action_card.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/email_verification_banner.dart';
import '../../../recycling/domain/entities/recycling_session.dart';
import '../../../recycling/domain/entities/waste_type.dart';
import '../../../recycling/presentation/pages/active_session_page.dart';
import '../../../recycling/presentation/pages/scan_bin_page.dart';
import '../../../recycling/presentation/pages/select_waste_page.dart';
import '../../../recycling/presentation/pages/show_bin_qr_page.dart';
import '../../../recycling/presentation/providers/recycling_providers.dart';
import '../../../recycling/presentation/providers/session_auto_close_provider.dart';
import '../../../wallet/presentation/pages/history_page.dart';
import '../../../wallet/presentation/widgets/points_balance_card.dart';

/// Giriş yapılınca gösterilen ana sayfa.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final ongoing = ref.watch(ongoingSessionProvider).value;

    // Uygulama yeniden açıldığında geride kalmış oturum varsa (o sırada
    // hiçbir ekran onu izlemiyor) otomatik kapatma sırasına al.
    ref.listen(ongoingSessionProvider, (previous, next) {
      final session = next.value;
      if (session == null) return;
      ref.read(sessionAutoCloseProvider.notifier).gerekiyorsaKapat(session.id);
    });

    // Ad henüz yüklenmediyse ya da eski kayıtlarda boşsa, Firebase Auth
    // profilindeki adı, o da yoksa e-postanın @ öncesini kullanıyoruz —
    // karşılama satırı hiç boş kalmasın.
    final authUser = ref.watch(authStateProvider).value;
    final gorunenAd = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : (authUser?.displayName?.isNotEmpty ?? false)
            ? authUser!.displayName!
            : (authUser?.email?.split('@').first ?? '');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _Karsilama(ad: gorunenAd),
            const SizedBox(height: 20),
            const EmailVerificationBanner(),
            if (ongoing != null) ...[
              _DevamEdenOturumUyarisi(session: ongoing),
              const SizedBox(height: 14),
            ],
            const PointsBalanceCard(),
            const SizedBox(height: 22),
            const _BolumBasligi('Ne yapmak istersin?'),
            const SizedBox(height: 12),
            BigActionCard(
              color: AppColors.green,
              icon: Icons.qr_code_scanner_rounded,
              title: 'Atık At',
              subtitle: 'Kutunun QR kodunu okut, puan kazan',
              onTap: () => _atikAtmayaBasla(context, ref),
            ),
            const SizedBox(height: 14),
            BigActionCard(
              color: const Color(0xFF7C3AED),
              icon: Icons.history_rounded,
              title: 'Puan Geçmişi',
              subtitle: 'Kazandıkların ve harcadıkların',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              ),
            ),
            // Bu buton SADECE geliştirme modunda görünür. Gerçek kutunun
            // basılı QR etiketi olmadığı için, test amaçlı QR'ı ekranda
            // gösteren sayfayı açıyor.
            if (kDebugMode) ...[
              const SizedBox(height: 28),
              const Divider(),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Test Kutusu QR Kodu'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShowBinQrPage()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _atikAtmayaBasla(BuildContext context, WidgetRef ref) async {
    // 1) Önce kutunun QR'ını okut — dönen değer binId'dir.
    final binId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanBinPage()),
    );
    // Kullanıcı taramadan geri döndüyse (binId null) hiçbir şey yapma.
    if (binId == null) return;
    if (!context.mounted) return;

    // 2) binId elimizde — şimdi atık türü seçim ekranına geç.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SelectWastePage(binId: binId)),
    );
  }
}

class _Karsilama extends StatelessWidget {
  const _Karsilama({required this.ad});
  final String ad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merhaba',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          ad.isEmpty ? 'Hoş geldin!' : ad,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  const _BolumBasligi(this.metin);
  final String metin;

  @override
  Widget build(BuildContext context) {
    return Text(
      metin.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Yarıda kalmış bir atık atma işlemi olduğunda beliren uyarı.
class _DevamEdenOturumUyarisi extends StatelessWidget {
  const _DevamEdenOturumUyarisi({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActiveSessionPage(
                  sessionId: session.id,
                  binId: session.binId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.pending_actions_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Devam eden bir işlemin var',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.wasteType.label} — dokun ve devam et',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
