import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/entities/waste_type.dart';
import '../models/recycling_session_model.dart';

class RecyclingRemoteDataSource {
  RecyclingRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(FirestorePaths.sessions);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  Future<String> startSession({
    required String uid,
    required String binId,
    required WasteType wasteType,
  }) async {
    // .add(): Firestore'a yeni bir belge ekler ve rastgele bir id üretir.
    final docRef = await _sessions.add(
      RecyclingSessionModel.initialMap(uid: uid, binId: binId, wasteType: wasteType),
    );
    return docRef.id;
  }

  Stream<RecyclingSessionModel> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map(RecyclingSessionModel.fromSnapshot);
  }

  Future<void> updateStatus(String sessionId, SessionStatus status) {
    return _sessions.doc(sessionId).update({'status': status.id});
  }

  Future<void> incrementDepositedCount(String sessionId) {
    // FieldValue.increment: sunucu tarafında ATOMİK olarak +1 yapar.
    // "önce oku, +1 ekle, geri yaz" yapsaydık, aynı anda iki yazma
    // gelirse biri kaybolabilirdi; increment bunu imkansız kılar.
    return _sessions.doc(sessionId).update({'depositedCount': FieldValue.increment(1)});
  }

  /// Oturumun puanını kullanıcıya KESİN OLARAK BİR KEZ ekler.
  Future<void> claimPoints(RecyclingSession session) {
    final sessionRef = _sessions.doc(session.id);
    final userRef = _users.doc(session.uid);

    // runTransaction: içindeki okuma+yazmalar TEK bir bütün olarak çalışır.
    // Aynı oturum için iki farklı yerden (ör. çift tıklama, iki cihaz)
    // aynı anda çağrılsa bile puan sadece bir kez eklenir.
    return _firestore.runTransaction((tx) async {
      final sessionSnap = await tx.get(sessionRef);
      final alreadyClaimed = (sessionSnap.data()?['pointsClaimed'] as bool?) ?? false;
      if (alreadyClaimed) return; // Güvenlik kilidi: ikinci çağrı hiçbir şey yapmaz.

      tx.update(userRef, {'points': FieldValue.increment(session.pointsEarned)});
      tx.update(sessionRef, {'pointsClaimed': true});
    });
  }
}
