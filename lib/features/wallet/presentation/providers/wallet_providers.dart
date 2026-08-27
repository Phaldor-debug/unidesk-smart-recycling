import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/points_balance.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/watch_points_balance.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(ref.watch(firestoreProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDataSourceProvider));
});

final watchPointsBalanceProvider = Provider(
  (ref) => WatchPointsBalance(ref.watch(walletRepositoryProvider)),
);

/// O an giriş yapmış kullanıcının puan bakiyesini canlı yayınlar.
/// authStateProvider'ı izleyerek uid'yi alır; kullanıcı değişirse
/// (çıkış/farklı hesapla giriş) otomatik olarak doğru bakiyeye geçer.
final pointsBalanceProvider = StreamProvider<PointsBalance>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    // Oturum yokken bu provider zaten kullanılmayacak (AuthGate LoginPage
    // gösterir), ama tip güvenliği için boş bir akış döndürüyoruz.
    return const Stream.empty();
  }
  return ref.watch(watchPointsBalanceProvider).call(user.uid);
});
