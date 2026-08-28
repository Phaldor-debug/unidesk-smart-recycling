import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../recycling/data/datasources/recycling_remote_datasource.dart'
    show suankiDonem;
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  /// Sıralama, harcanabilir bakiyeye (`points`) DEĞİL, o ay KAZANILAN
  /// puana (`monthlyPoints`) göre yapılır.
  ///
  /// Sebep: bakiyeye göre sıralasaydık, ödül kullanan kişi puanı düştüğü
  /// için sıralamada geriye düşerdi — yani sistemi en çok kullanan kişi
  /// cezalandırılmış olurdu. Aylık kazanç sayacı sadece artar.
  ///
  /// `monthlyPeriod` filtresi şart: bu alan olmadan geçen ay yüksek puan
  /// alıp bu ay hiç atık atmayan kullanıcılar listede kalmaya devam ederdi.
  Stream<List<LeaderboardEntry>> watchTop({required int limit}) {
    final donem = suankiDonem();

    return _firestore
        .collection(FirestorePaths.users)
        .where('monthlyPeriod', isEqualTo: donem)
        .orderBy('monthlyPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      // Sıra numarasını istemcide veriyoruz: sorgu sonucu zaten puana
      // göre sıralı geldiği için indeks + 1 doğru sırayı verir.
      return List.generate(snap.docs.length, (index) {
        final data = snap.docs[index].data();
        return LeaderboardEntry(
          uid: snap.docs[index].id,
          displayName: data['displayName'] as String? ?? '',
          points: data['monthlyPoints'] as int? ?? 0,
          rank: index + 1,
        );
      });
    });
  }
}
