import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../recycling/domain/entities/waste_type.dart';
import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.kind,
    required super.title,
    required super.points,
    required super.date,
  });

  /// Bir atık atma oturumundan "puan kazanıldı" satırı üretir.
  /// Puanı burada yeniden HESAPLAMIYORUZ; oturumdaki adet ve türden
  /// aynı kuralla (WasteType.pointsPerItem) türetiyoruz — puan kuralı
  /// tek yerde tanımlı kalsın diye.
  factory WalletTransactionModel.fromSession(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const {};
    final wasteType = WasteTypeX.fromId(data['wasteType'] as String? ?? '');
    final count = data['depositedCount'] as int? ?? 0;

    return WalletTransactionModel(
      id: snapshot.id,
      kind: TransactionKind.earned,
      title: '${wasteType.label} — $count adet',
      points: count * wasteType.pointsPerItem,
      date: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Bir ödül kullanımından "puan harcandı" satırı üretir.
  /// costPoints, hakkın alındığı ANDAKİ fiyattır (redemption belgesine
  /// kopyalanmıştır) — ödülün güncel fiyatı değişse bile geçmiş bozulmaz.
  factory WalletTransactionModel.fromRedemption(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const {};
    return WalletTransactionModel(
      id: snapshot.id,
      kind: TransactionKind.spent,
      title: data['rewardTitle'] as String? ?? 'Ödül',
      // Bu alan eklenmeden önce oluşturulmuş eski kayıtlarda 0 görünür.
      points: data['costPoints'] as int? ?? 0,
      date: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
