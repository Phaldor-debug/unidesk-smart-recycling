import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<List<LeaderboardEntry>> watchTop({required int limit}) {
    return _firestore
        .collection(FirestorePaths.users)
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      // Sıra numarasını istemcide veriyoruz: Firestore sorgu sonucu
      // zaten puana göre sıralı geldiği için indeks + 1 doğru sırayı verir.
      return List.generate(snap.docs.length, (index) {
        final data = snap.docs[index].data();
        return LeaderboardEntry(
          uid: snap.docs[index].id,
          displayName: data['displayName'] as String? ?? '',
          points: data['points'] as int? ?? 0,
          rank: index + 1,
        );
      });
    });
  }
}
