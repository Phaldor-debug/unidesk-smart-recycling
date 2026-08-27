import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/recycling_session.dart';
import '../../domain/entities/waste_type.dart';

class RecyclingSessionModel extends RecyclingSession {
  const RecyclingSessionModel({
    required super.id,
    required super.uid,
    required super.binId,
    required super.wasteType,
    required super.status,
    required super.depositedCount,
    required super.pointsClaimed,
  });

  /// Firestore'dan gelen belgeyi (id + veri) modele çevirir.
  /// Eksik/bozuk alanlarda uygulama çökmesin diye güvenli varsayılanlar kullanılır.
  factory RecyclingSessionModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const {};
    return RecyclingSessionModel(
      id: snapshot.id,
      uid: data['uid'] as String? ?? '',
      binId: data['binId'] as String? ?? '',
      wasteType: WasteTypeX.fromId(data['wasteType'] as String? ?? ''),
      status: SessionStatusX.fromId(data['status'] as String? ?? ''),
      depositedCount: data['depositedCount'] as int? ?? 0,
      pointsClaimed: data['pointsClaimed'] as bool? ?? false,
    );
  }

  /// Yeni bir oturum oluştururken Firestore'a yazılacak başlangıç verisi.
  static Map<String, dynamic> initialMap({
    required String uid,
    required String binId,
    required WasteType wasteType,
  }) {
    return {
      'uid': uid,
      'binId': binId,
      'wasteType': wasteType.id,
      'status': SessionStatus.pending.id,
      'depositedCount': 0,
      'pointsClaimed': false,
      // serverTimestamp: cihazın kendi saatine değil, Firebase sunucusunun
      // saatine güveniyoruz — cihaz saati yanlış ayarlıysa bile doğru sıralanır.
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
