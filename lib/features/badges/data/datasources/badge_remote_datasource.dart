import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/utils/period.dart';
import '../../../recycling/domain/entities/waste_type.dart';
import '../../domain/entities/badge.dart';
import '../../domain/entities/badge_stats.dart';

class BadgeRemoteDataSource {
  BadgeRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  /// Kullanıcının istatistiklerini ve kazandığı rozetleri CANLI izler.
  Stream<({BadgeStats stats, List<String> kazanilanlar})> watchBadgeState(String uid) {
    return _userRef(uid).snapshots().map((snap) {
      final data = snap.data() ?? const <String, dynamic>{};
      return (
        stats: _statsFromMap(data),
        kazanilanlar: (data['badges'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
    });
  }

  static BadgeStats _statsFromMap(Map<String, dynamic> data) {
    final turHaritasi = <WasteType, int>{};
    final ham = data['itemsByType'] as Map<String, dynamic>? ?? const {};
    for (final tip in WasteType.values) {
      turHaritasi[tip] = (ham[tip.id] as int?) ?? 0;
    }

    // Aktif gün sayacı geçmiş bir aya aitse bu ay için 0 sayılmalı,
    // yoksa geçen ayın sayısı bu ayın rozetini haksız yere açardı.
    final aktifGunDonemi = data['activeDaysPeriod'] as String?;
    final aktifGun =
        aktifGunDonemi == suankiDonem() ? (data['activeDaysCount'] as int? ?? 0) : 0;

    return BadgeStats(
      totalItems: data['totalItems'] as int? ?? 0,
      itemsByType: turHaritasi,
      currentStreak: data['currentStreak'] as int? ?? 0,
      activeDaysThisMonth: aktifGun,
      registrationNo: data['registrationNo'] as int? ?? 0,
      podiumFinishes: data['podiumFinishes'] as int? ?? 0,
      championFinishes: data['championFinishes'] as int? ?? 0,
    );
  }

  /// Hak edilmiş ama henüz verilmemiş rozetleri verir ve bonus puanı yazar.
  /// Yeni kazanılan rozetleri döner (kutlama göstermek için).
  ///
  /// Transaction: aynı anda iki yerden çağrılsa bile bir rozet iki kez
  /// verilmez ve bonus puan iki kez eklenmez.
  Future<List<Achievement>> checkAndAward(String uid) async {
    final ref = _userRef(uid);
    final yeniKazanilanlar = <Achievement>[];

    await _firestore.runTransaction((tx) async {
      yeniKazanilanlar.clear();

      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;

      final stats = _statsFromMap(data);
      final mevcut = (data['badges'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toSet();

      for (final rozet in tumRozetler) {
        if (mevcut.contains(rozet.id)) continue;
        if (!rozet.kazanildiMi(stats)) continue;
        yeniKazanilanlar.add(rozet);
      }

      if (yeniKazanilanlar.isEmpty) return;

      final bonus = yeniKazanilanlar.fold<int>(0, (t, r) => t + r.bonusPoints);
      tx.update(ref, {
        'badges': FieldValue.arrayUnion(yeniKazanilanlar.map((r) => r.id).toList()),
        // Bonus puan SADECE harcanabilir bakiyeye. monthly_scores'a
        // yazılmıyor: sıralama saf olarak "bu ay ne kadar atık attın"ı
        // ölçmeye devam etsin diye.
        'points': FieldValue.increment(bonus),
      });
    });

    return yeniKazanilanlar;
  }

  /// Geçen ayı ilk 3'te bitirdiyse sıralama rozetlerinin sayacını artırır.
  ///
  /// Ay kapandıktan sonra bir kez çalışmalı; `lastRankCheck` alanı aynı
  /// ay için tekrar sayılmasını engelliyor.
  Future<void> gecenAyiDegerlendir(String uid) async {
    final donem = oncekiDonem();
    final ref = _userRef(uid);

    // Geçen ayın ilk 3'ü — sıralama koleksiyonundan.
    final ilkUc = await _firestore
        .collection(FirestorePaths.monthlyScores)
        .where('period', isEqualTo: donem)
        .orderBy('points', descending: true)
        .limit(3)
        .get();

    final sira = ilkUc.docs.indexWhere((d) => (d.data()['uid'] as String?) == uid);
    if (sira == -1) {
      // İlk 3'te değil; yine de tekrar sorgulamamak için işaretliyoruz.
      await ref.set({'lastRankCheck': donem}, SetOptions(merge: true));
      return;
    }

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      if ((snap.data()?['lastRankCheck'] as String?) == donem) return;

      tx.update(ref, {
        'lastRankCheck': donem,
        'podiumFinishes': FieldValue.increment(1),
        if (sira == 0) 'championFinishes': FieldValue.increment(1),
      });
    });
  }

  /// Geçen ay için değerlendirme yapıldı mı?
  Future<bool> gecenAyDegerlendirildiMi(String uid) async {
    final snap = await _userRef(uid).get();
    return (snap.data()?['lastRankCheck'] as String?) == oncekiDonem();
  }
}
