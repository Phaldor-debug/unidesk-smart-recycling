import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';
import '../models/redemption_model.dart';
import '../models/reward_model.dart';

class RewardsRemoteDataSource {
  RewardsRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rewards =>
      _firestore.collection(FirestorePaths.rewards);

  CollectionReference<Map<String, dynamic>> get _redemptions =>
      _firestore.collection(FirestorePaths.redemptions);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  /// `rewards` koleksiyonundaki aktif ödülleri canlı dinler. Firebase
  /// Console'dan (veya ileride bir admin panelinden) eklenen/silinen/
  /// active'i değiştirilen her belge bu listeyi otomatik günceller.
  Stream<List<RewardModel>> watchRewards() {
    return _rewards.where('active', isEqualTo: true).snapshots().map(
          (snapshot) => snapshot.docs.map(RewardModel.fromSnapshot).toList(),
        );
  }

  /// Kullanıcının kullanılmamış (aktif) kodlarını canlı izler.
  Stream<List<RedemptionModel>> watchMyActiveRedemptions(String uid) {
    return _redemptions
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: RedemptionStatus.active.id)
        .snapshots()
        .map((snap) => snap.docs.map(RedemptionModel.fromSnapshot).toList());
  }

  Future<RedemptionModel> redeem({required String uid, required Reward reward}) async {
    final userRef = _users.doc(uid);
    // .doc() (parametresiz): id'yi ÖNCEDEN üretir ama belgeyi henüz
    // oluşturmaz. Transaction içinde bu id'yi kullanarak yazacağız.
    final redemptionRef = _redemptions.doc();
    final code = _generateCode();

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final currentPoints = (userSnap.data()?['points'] as int?) ?? 0;

      if (currentPoints < reward.costPoints) {
        // Transaction içinde fırlatılan hata: HİÇBİR yazma uygulanmaz,
        // puan da düşmez, kod da oluşmaz. Ekrana AppException olarak gider.
        throw AppException(
          'Yetersiz puan. Gereken: ${reward.costPoints}, mevcut: $currentPoints',
        );
      }

      tx.update(userRef, {'points': FieldValue.increment(-reward.costPoints)});
      tx.set(
        redemptionRef,
        RedemptionModel.initialMap(uid: uid, reward: reward, code: code),
      );
    });

    return RedemptionModel(
      id: redemptionRef.id,
      uid: uid,
      rewardId: reward.id,
      rewardTitle: reward.title,
      code: code,
      status: RedemptionStatus.active,
    );
  }

  Future<RedemptionModel?> findActiveByCode(String code) async {
    final query = await _redemptions
        .where('code', isEqualTo: code)
        .where('status', isEqualTo: RedemptionStatus.active.id)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return RedemptionModel.fromSnapshot(query.docs.first);
  }

  Future<void> markUsed(String redemptionId) {
    return _redemptions.doc(redemptionId).update({
      'status': RedemptionStatus.used.id,
      'usedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 6 haneli, insanın yemekhanede kolayca okuyup söyleyebileceği kod.
  ///
  /// Random.secure(): normal Random() tahmin edilebilir bir diziden üretir
  /// (aynı tohumdan aynı sonuçlar) — kodu tahmin edilebilir kılardı.
  /// secure() işletim sisteminin kriptografik üretecini kullanır.
  String _generateCode() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }
}
