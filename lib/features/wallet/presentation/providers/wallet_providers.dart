import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/points_balance.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/watch_points_balance.dart';
import '../../domain/usecases/watch_transactions.dart';

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
    // Oturum yokken bu provider zaten kullanılmamalı (AuthGate LoginPage
    // gösterir). Yine de bir yerden okunursa, hiç değer yaymayan bir akış
    // ekranı sonsuza kadar "yükleniyor"da bırakırdı — bunun yerine sıfır
    // bakiye yayınlıyoruz.
    return Stream.value(const PointsBalance(points: 0));
  }
  return ref.watch(watchPointsBalanceProvider).call(user.uid);
});

final watchTransactionsProvider = Provider(
  (ref) => WatchTransactions(ref.watch(walletRepositoryProvider)),
);

/// Giriş yapmış kullanıcının puan geçmişini (kazanç + harcama) canlı yayınlar.
final transactionsProvider = StreamProvider<List<WalletTransaction>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(watchTransactionsProvider).call(user.uid);
});
