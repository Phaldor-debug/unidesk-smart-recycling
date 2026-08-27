import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reward.dart';

class RewardModel extends Reward {
  const RewardModel({
    required super.id,
    required super.title,
    required super.costPoints,
    required super.active,
  });

  factory RewardModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const {};
    return RewardModel(
      id: snapshot.id,
      title: data['title'] as String? ?? '(isimsiz ödül)',
      costPoints: data['costPoints'] as int? ?? 0,
      active: data['active'] as bool? ?? true,
    );
  }
}
