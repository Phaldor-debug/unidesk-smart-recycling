import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/badge_remote_datasource.dart';
import '../../data/repositories/badge_repository_impl.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/badge_stats.dart';
import '../../domain/repositories/badge_repository.dart';

final badgeRemoteDataSourceProvider = Provider<BadgeRemoteDataSource>((ref) {
  return BadgeRemoteDataSource(ref.watch(firestoreProvider));
});

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepositoryImpl(ref.watch(badgeRemoteDataSourceProvider));
});

/// Kullanıcının rozet durumu: istatistikler + kazanılmış rozet kimlikleri.
final badgeStateProvider =
    StreamProvider<({BadgeStats stats, List<String> kazanilanlar})>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value((
      stats: const BadgeStats(
        totalItems: 0,
        itemsByType: {},
        currentStreak: 0,
        activeDaysThisMonth: 0,
        registrationNo: 0,
        podiumFinishes: 0,
        championFinishes: 0,
      ),
      kazanilanlar: const <String>[],
    ));
  }
  return ref.watch(badgeRepositoryProvider).watchBadgeState(user.uid);
});

/// Kazanılmış rozet sayısı — profil ekranındaki özet kutusu için.
final badgeCountProvider = Provider<int>((ref) {
  return ref.watch(badgeStateProvider).value?.kazanilanlar.length ?? 0;
});

/// Rozet kontrolünü yürüten ve yeni kazanılanları duyuran denetleyici.
///
/// State: en son kazanılan rozetler. Ekranlar bunu dinleyip kutlama
/// gösterir, sonra [temizle] ile sıfırlar.
class BadgeChecker extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() {
    ref.keepAlive();
    return const [];
  }

  /// Puan kazanıldıktan sonra çağrılır: hak edilen rozet var mı diye bakar.
  Future<void> kontrolEt() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final repository = ref.read(badgeRepositoryProvider);
    try {
      // Ay kapandıysa önce sıralama rozetlerinin sayacını güncelle ki
      // aynı turda podyum/şampiyon rozeti de verilebilsin.
      if (!await repository.gecenAyDegerlendirildiMi(uid)) {
        await repository.gecenAyiDegerlendir(uid);
      }

      final yeniler = await repository.checkAndAward(uid);
      if (yeniler.isNotEmpty) state = yeniler;
    } catch (_) {
      // Rozet verilemezse akış bozulmasın; bir sonraki atışta tekrar
      // denenecek. Rozetler puanın kendisi kadar kritik değil.
    }
  }

  /// Kutlama gösterildikten sonra çağrılır.
  void temizle() => state = const [];
}

final badgeCheckerProvider =
    NotifierProvider<BadgeChecker, List<Achievement>>(BadgeChecker.new);
