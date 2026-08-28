import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
// Firebase'in çekirdek paketi: Firebase.initializeApp burada.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// flutterfire configure komutunun ürettiği dosya: her platformun API anahtarları.
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/big_action_card.dart';
// authStateProvider: oturum durumunu canlı dinleyen provider.
import 'features/auth/presentation/providers/auth_providers.dart';
// authControllerProvider: giriş/kayıt/çıkış işlemlerini yürüten controller.
import 'features/auth/presentation/providers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/wallet/presentation/pages/history_page.dart';
import 'features/wallet/presentation/widgets/points_balance_card.dart';
import 'features/recycling/presentation/pages/active_session_page.dart';
import 'features/recycling/presentation/pages/scan_bin_page.dart';
import 'features/recycling/presentation/providers/recycling_providers.dart';
import 'features/recycling/domain/entities/recycling_session.dart';
import 'features/recycling/domain/entities/waste_type.dart';
import 'features/recycling/presentation/pages/select_waste_page.dart';
import 'features/recycling/presentation/pages/show_bin_qr_page.dart';
import 'features/rewards/presentation/pages/rewards_page.dart';

// main artık `async` çünkü Firebase başlatmayı `await` edeceğiz.
Future<void> main() async {
  // Flutter motoru ile Android/iOS native tarafı arasındaki köprüyü kurar.
  // runApp'ten ÖNCE native kod (Firebase) çağıracaksak zorunludur.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i bu cihazın platformuna ait ayarlarla başlatır.
  // DefaultFirebaseOptions.currentPlatform, firebase_options.dart içinden gelir
  // ve çalıştığın platforma (Android/iOS/web) göre doğru ayarı seçer.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope: Riverpod'un TÜM provider'ları sakladığı kök depo.
  // Uygulamanın en tepesinde olmak zorunda; olmazsa hiçbir provider okunamaz.
  runApp(
    const ProviderScope(
      child: UnideskApp(),
    ),
  );
}

// ConsumerWidget = provider okuyabilen StatelessWidget.
// Normal StatelessWidget'tan farkı: build metoduna fazladan `ref` gelir.
class UnideskApp extends ConsumerWidget {
  const UnideskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ünidesk Geri Dönüşüm',
      // Sağ üstteki "DEBUG" şeridini kaldırır.
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Cihazın açık/koyu tema ayarına otomatik uyar.
      themeMode: ThemeMode.system,
      // İlk açılan widget: oturum durumuna karar veren "kapı".
      home: const AuthGate(),
    );
  }
}

/// Oturum durumuna göre hangi ekranın gösterileceğine karar verir.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authStateProvider'ı izliyoruz. Sonucu AsyncValue<User?> tipinde;
    // .when ile 3 durumu ayrı ayrı ele alıyoruz.
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // 1) Akıştan bir değer geldi.
      data: (user) {
        if (user == null) {
          // Giriş yapılmamış → giriş ekranını göster.
          return const LoginPage();
        }
        // Giriş yapılmış → ana sayfa.
        return const HomePage();
      },
      // 2) Akış ilk değerini henüz yaymadı → yükleniyor çemberi.
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // 3) Hata (ağ yok, Firebase yapılandırması bozuk vb.).
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Bir hata oluştu:\n$error', textAlign: TextAlign.center)),
      ),
    );
  }
}

/// Giriş yapılınca gösterilen ana sayfa.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final ongoing = ref.watch(ongoingSessionProvider).value;
    // Ad henüz yüklenmediyse ya da eski kayıtlarda boşsa e-postanın
    // @ öncesini kullanıyoruz — karşılama satırı hiç boş kalmasın.
    final gorunenAd = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName
        : (user?.email.split('@').first ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ünidesk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Puan geçmişi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profilim',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              gorunenAd.isEmpty ? 'Hoş geldin!' : 'Hoş geldin, $gorunenAd',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          // Kullanıcı atma ekranından çıktıysa oturum askıda kalıyor.
          // Buradan geri dönebilsin — yoksa kapak açık kalır ve attığı
          // atıklar Firestore'a yansımaz.
          if (ongoing != null) ...[
            _DevamEdenOturumUyarisi(session: ongoing),
            const SizedBox(height: 12),
          ],
          // Puan bakiyesi kartı: Firestore'daki 'points' alanını canlı gösterir.
          const PointsBalanceCard(),
          const SizedBox(height: 8),
          BigActionCard(
            color: AppTheme.light.colorScheme.primary,
            icon: Icons.qr_code_scanner_rounded,
            title: 'Atık At',
            subtitle: 'Kutunun QR\'ını okut, puan kazan',
            onTap: () async {
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
            },
          ),
          const SizedBox(height: 16),
          BigActionCard(
            color: const Color(0xFF7C3AED), // mor — ödülleri diğer aksiyonlardan ayırt eder
            icon: Icons.card_giftcard_rounded,
            title: 'Ödüller',
            subtitle: 'Puanını harca, hak kazan',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RewardsPage()),
              );
            },
          ),
          // Bu buton SADECE geliştirme modunda görünür. Gerçek kutunun
          // basılı QR etiketi olmadığı için, test amaçlı QR'ı ekranda
          // gösteren sayfayı açıyor — bkz. show_bin_qr_page.dart.
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            const Divider(),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('🔧 Test Kutusu QR\'ını Göster'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShowBinQrPage()),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Yarıda kalmış bir atık atma işlemi olduğunda ana sayfada beliren uyarı.
class _DevamEdenOturumUyarisi extends StatelessWidget {
  const _DevamEdenOturumUyarisi({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context) {
    return Material(
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
    );
  }
}
