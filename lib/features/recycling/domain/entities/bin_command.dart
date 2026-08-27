import 'recycling_session.dart';
import 'waste_type.dart';

/// Realtime Database'de `/bin_commands/{binId}` yolunda tutulan, ESP32'nin
/// izlediği CANLI komut. `RecyclingSession`'ın "hafif" bir kopyası gibi
/// düşünülebilir — Firestore'daki tam kayıt (puan, sahiplik vb.) burada
/// yok, sadece donanımın bilmesi gereken 4 alan var.
class BinCommand {
  const BinCommand({
    required this.sessionId,
    required this.wasteType,
    required this.status,
    required this.depositedCount,
  });

  final String sessionId;
  final WasteType wasteType;
  final SessionStatus status;
  final int depositedCount;
}
