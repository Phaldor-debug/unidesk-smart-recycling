import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/redemption.dart';
import '../../domain/entities/reward.dart';

class RedemptionModel extends Redemption {
  const RedemptionModel({
    required super.id,
    required super.uid,
    required super.rewardId,
    required super.rewardTitle,
    required super.code,
    required super.status,
  });

  factory RedemptionModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const {};
    return RedemptionModel(
      id: snapshot.id,
      uid: data['uid'] as String? ?? '',
      rewardId: data['rewardId'] as String? ?? '',
      rewardTitle: data['rewardTitle'] as String? ?? '',
      code: data['code'] as String? ?? '',
      status: RedemptionStatusX.fromId(data['status'] as String? ?? ''),
    );
  }

  static Map<String, dynamic> initialMap({
    required String uid,
    required Reward reward,
    required String code,
  }) {
    return {
      'uid': uid,
      'rewardId': reward.id,
      // Ödülün o anki adını KOPYALIYORUZ (bkz. Redemption.rewardTitle yorumu).
      'rewardTitle': reward.title,
      'code': code,
      'status': RedemptionStatus.active.id,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
