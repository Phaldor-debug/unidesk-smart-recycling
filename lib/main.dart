import 'package:flutter/material.dart';
// Firebase'in çekirdek paketi: Firebase.initializeApp burada.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// flutterfire configure komutunun ürettiği dosya: her platformun API anahtarları.
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
// authStateProvider: oturum durumunu canlı dinleyen provider.
import 'features/auth/presentation/providers/auth_providers.dart';
import 'shared/navigation/main_shell.dart';

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
        // Giriş yapılmış → alt gezinme çubuklu ana iskelet.
        return const MainShell();
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
