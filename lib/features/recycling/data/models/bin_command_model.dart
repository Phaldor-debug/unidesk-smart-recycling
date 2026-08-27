import '../../domain/entities/bin_command.dart';
import '../../domain/entities/recycling_session.dart';
import '../../domain/entities/waste_type.dart';

class BinCommandModel extends BinCommand {
  const BinCommandModel({
    required super.sessionId,
    required super.wasteType,
    required super.status,
    required super.depositedCount,
  });

  /// RTDB'den gelen Map'i (JSON ağacı) modele çevirir.
  /// RTDB'de o an bir komut yoksa `data` null gelir.
  static BinCommandModel? fromMap(Map<dynamic, dynamic>? data) {
    if (data == null) return null;
    return BinCommandModel(
      sessionId: data['sessionId'] as String? ?? '',
      wasteType: WasteTypeX.fromId(data['wasteType'] as String? ?? ''),
      status: SessionStatusX.fromId(data['status'] as String? ?? ''),
      depositedCount: (data['depositedCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Yeni bir oturum başlarken ESP32'nin göreceği ilk komut.
  static Map<String, dynamic> initialMap({
    required String sessionId,
    required WasteType wasteType,
  }) {
    return {
      'sessionId': sessionId,
      'wasteType': wasteType.id,
      'status': SessionStatus.pending.id,
      'depositedCount': 0,
    };
  }
}
