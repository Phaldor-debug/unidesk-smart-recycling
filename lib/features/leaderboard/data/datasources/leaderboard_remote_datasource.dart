import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/utils/period.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  /// Sıralama, harcanabilir bakiyeye DEĞİL, o ay KAZANILAN puana göre.
  ///
  /// Sebep: bakiyeye göre sıralasaydık, ödül kullanan kişi puanı düştüğü
  /// için sıralamada geriye düşerdi — sistemi en çok kullananı
  /// cezalandırmış olurduk.
  ///
  /// Veri `monthly_scores` koleksiyonundan geliyor; her ay ayrı kayıt
  /// olduğu için geçmiş aylar da aynı sorguyla okunabiliyor.
  Stream<List<LeaderboardEntry>> watchTop({required int limit, String? donem}) {
    final hedefDonem = donem ?? suankiDonem();

    return _firestore
        .collection(FirestorePaths.monthlyScores)
        .where('period', isEqualTo: hedefDonem)
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      // Sıra numarasını istemcide veriyoruz: sorgu sonucu zaten puana
      // göre sıralı geldiği için indeks + 1 doğru sırayı verir.
      return List.generate(snap.docs.length, (index) {
        final data = snap.docs[index].data();
        return LeaderboardEntry(
          uid: data['uid'] as String? ?? '',
          displayName: data['displayName'] as String? ?? '',
          points: data['points'] as int? ?? 0,
          rank: index + 1,
        );
      });
    });
  }
}
