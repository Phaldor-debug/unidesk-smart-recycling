import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/utils/period.dart';
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

  CollectionReference<Map<String, dynamic>> get _monthlyScores =>
      _firestore.collection(FirestorePaths.monthlyScores);

  /// Yazmadan ÖNCE bir belge kimliği üretir.
  ///
  /// Neden gerekli: `.add()` ile yazıp kimliği sonradan öğrenmek yarışa
  /// yol açıyordu. Firestore, yazma sunucuya ulaşmadan yerel bir anlık
  /// görüntü yayınlıyor (gecikme telafisi); ana sayfadaki temizleyici bu
  /// bildirimi görüp oturumu "sahipsiz" sanarak daha doğar doğmaz
  /// kapatıyordu. Kimliği önce üretince oturumu korumaya alıp sonra
  /// yazabiliyoruz.
  String yeniOturumKimligi() => _sessions.doc().id;

  Future<void> startSession({
    required String sessionId,
    required String uid,
    required String binId,
    required WasteType wasteType,
  }) {
    return _sessions.doc(sessionId).set(
          RecyclingSessionModel.initialMap(uid: uid, binId: binId, wasteType: wasteType),
        );
  }

  Stream<RecyclingSessionModel> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map(RecyclingSessionModel.fromSnapshot);
  }

  Stream<RecyclingSessionModel?> watchOngoingSession(String uid) {
    return _sessions
        .where('uid', isEqualTo: uid)
        .where('status', whereIn: [SessionStatus.pending.id, SessionStatus.lidOpen.id])
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : RecyclingSessionModel.fromSnapshot(snap.docs.first));
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

  /// Donanımdan gelen durum + sayacı TEK bir update ile yazar.
  /// İkisini ayrı ayrı yazmak yarış durumu yaratıyordu (bkz. repository
  /// arayüzündeki açıklama), bu yüzden bilerek birleştirildi.
  Future<void> applyHardwareUpdate({
    required String sessionId,
    required SessionStatus status,
    required int depositedCount,
  }) {
    return _sessions.doc(sessionId).update({
      'status': status.id,
      'depositedCount': depositedCount,
    });
  }

  /// Oturumun puanını kullanıcıya KESİN OLARAK BİR KEZ ekler.
  Future<void> claimPoints(RecyclingSession session) {
    final sessionRef = _sessions.doc(session.id);
    final userRef = _users.doc(session.uid);

    // runTransaction: içindeki okuma+yazmalar TEK bir bütün olarak çalışır.
    // Aynı oturum için iki farklı yerden (ör. çift tıklama, iki cihaz)
    // aynı anda çağrılsa bile puan sadece bir kez eklenir.
    final donem = suankiDonem();
    // Belge kimliğini uid+dönemden üretiyoruz: aynı ay için ikinci bir
    // kayıt oluşması imkânsız, ayrıca sorgulamadan doğrudan erişilebiliyor.
    final scoreRef = _monthlyScores.doc('${session.uid}_$donem');

    return _firestore.runTransaction((tx) async {
      // Firestore transaction kuralı: TÜM okumalar yazmalardan önce olmalı.
      final sessionSnap = await tx.get(sessionRef);
      if (!sessionSnap.exists) return;

      // Puanı, çağıran taraftan gelen (muhtemelen eskimiş) `session`
      // nesnesinden DEĞİL, transaction içinde okunan TAZE veriden
      // hesaplıyoruz. Aksi halde ekranın elindeki kopya bir an geride
      // kalmışsa yanlış puan yazılırdı.
      final fresh = RecyclingSessionModel.fromSnapshot(sessionSnap);
      if (fresh.pointsClaimed) return; // Güvenlik kilidi: ikinci çağrı hiçbir şey yapmaz.

      final userSnap = await tx.get(userRef);
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final kazanilan = fresh.pointsEarned;
      final adet = fresh.depositedCount;

      // --- Seri (streak) hesabı ---
      // Aynı gün tekrar atarsa seri değişmez; ertesi gün atarsa artar;
      // bir gün atlarsa baştan başlar.
      final bugun = gunKimligi();
      final sonGun = userData['lastThrowDay'] as String?;
      final oncekiSeri = userData['currentStreak'] as int? ?? 0;
      final int yeniSeri;
      if (sonGun == null) {
        yeniSeri = 1;
      } else if (sonGun == bugun) {
        yeniSeri = oncekiSeri == 0 ? 1 : oncekiSeri;
      } else if (gunFarki(sonGun, bugun) == 1) {
        yeniSeri = oncekiSeri + 1;
      } else {
        yeniSeri = 1;
      }

      // --- Bu ay kaç FARKLI günde atık atıldı ---
      // "Dönem Boyu" rozeti üst üste değil, dağınık da olsa düzenli
      // kullanımı ödüllendiriyor. Ay değişince sayaç sıfırlanır.
      final donemDegisti = (userData['activeDaysPeriod'] as String?) != donem;
      final yeniGunMu = sonGun != bugun;
      final oncekiAktifGun = userData['activeDaysCount'] as int? ?? 0;
      final int aktifGun;
      if (donemDegisti) {
        aktifGun = 1;
      } else if (yeniGunMu) {
        aktifGun = oncekiAktifGun + 1;
      } else {
        aktifGun = oncekiAktifGun == 0 ? 1 : oncekiAktifGun;
      }

      // Harcanabilir bakiye + rozet koşullarının dayandığı sayaçlar.
      // Bunlar kullanıcı belgesinde birikiyor; rozet kontrolü sonradan
      // bu alanları okuyup hangi rozetlerin hak edildiğine bakacak.
      tx.update(userRef, {
        'points': FieldValue.increment(kazanilan),
        'totalItems': FieldValue.increment(adet),
        'itemsByType.${fresh.wasteType.id}': FieldValue.increment(adet),
        'currentStreak': yeniSeri,
        'lastThrowDay': bugun,
        'activeDaysCount': aktifGun,
        'activeDaysPeriod': donem,
      });

      // Sıralama skoru: aya özel kayıtta birikir, ödül harcaması bunu
      // düşürmez. merge:true + increment sayesinde kayıt yoksa oluşur,
      // varsa üzerine eklenir.
      tx.set(
        scoreRef,
        {
          'uid': session.uid,
          // Ad sıralamada gösterilecek; kullanıcı belgesini herkese
          // açmamak için buraya kopyalıyoruz.
          'displayName': userSnap.data()?['displayName'] as String? ?? '',
          'period': donem,
          'points': FieldValue.increment(kazanilan),
        },
        SetOptions(merge: true),
      );

      tx.update(sessionRef, {'pointsClaimed': true});
    });
  }
}
