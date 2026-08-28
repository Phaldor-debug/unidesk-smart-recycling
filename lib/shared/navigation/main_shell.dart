import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/rewards/presentation/pages/rewards_page.dart';
import '../../features/rewards/presentation/providers/rewards_providers.dart';

/// Uygulamanın ana iskeleti: alt gezinme çubuğu ve sekmeler.
///
/// IndexedStack kullanıyoruz (sekme değişince widget'ı yeniden kurmak
/// yerine gizliyoruz): sekmeler arası geçişte kaydırma konumu ve
/// açık dinleyiciler korunuyor, geçiş anında yükleme çemberi görünmüyor.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Ödüller sekmesi bir özellik anahtarına bağlı; şu an kapalı,
    // bkz. AppConstants.odulSistemiAcik.
    final odullerAcik = AppConstants.odulSistemiAcik;

    // Kullanılmamış kod varsa sekmede rozet göster — kullanıcı elinde
    // bekleyen hakkı olduğunu fark etsin.
    final kodSayisi =
        odullerAcik ? (ref.watch(myActiveRedemptionsProvider).value?.length ?? 0) : 0;

    final sayfalar = <Widget>[
      const HomePage(),
      if (odullerAcik) const RewardsPage(),
      const LeaderboardPage(),
      const ProfilePage(),
    ];

    final hedefler = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Ana Sayfa',
      ),
      if (odullerAcik)
        NavigationDestination(
          icon: Badge(
            isLabelVisible: kodSayisi > 0,
            label: Text('$kodSayisi'),
            child: const Icon(Icons.card_giftcard_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: kodSayisi > 0,
            label: Text('$kodSayisi'),
            child: const Icon(Icons.card_giftcard_rounded),
          ),
          label: 'Ödüller',
        ),
      const NavigationDestination(
        icon: Icon(Icons.leaderboard_outlined),
        selectedIcon: Icon(Icons.leaderboard_rounded),
        label: 'Sıralama',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: sayfalar),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: hedefler,
      ),
    );
  }
}
