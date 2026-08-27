import 'waste_type.dart';

/// Bir oturumun hayat döngüsü. ESP32 firmware'i (ileride) ve şimdilik
/// bizim simülatörümüz bu durumları SIRAYLA yazacak:
/// pending -> lidOpen -> completed
enum SessionStatus {
  /// Oturum Firestore'da oluşturuldu, ESP32 henüz görmedi / kapağı açmadı.
  pending,

  /// Kapak açık, kullanıcı atığı atabilir. IR sensör her algılamada
  /// depositedCount artar.
  lidOpen,

  /// Kapak kapandı, sayım kesinleşti. Flutter tarafı artık puanı
  /// kullanıcıya ekleyebilir.
  completed,
}

extension SessionStatusX on SessionStatus {
  String get id => name;

  static SessionStatus fromId(String id) {
    return SessionStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => SessionStatus.pending,
    );
  }
}

/// Bir "atık atma oturumu"nun uygulama içindeki temsili.
class RecyclingSession {
  const RecyclingSession({
    required this.id,
    required this.uid,
    required this.binId,
    required this.wasteType,
    required this.status,
    required this.depositedCount,
    required this.pointsClaimed,
  });

  final String id;
  final String uid;
  final String binId;
  final WasteType wasteType;
  final SessionStatus status;
  final int depositedCount;

  /// Puan kullanıcıya eklendi mi? Aynı oturumdan iki kere puan
  /// eklenmesini önlemek için kullanılır (bkz. claimPoints).
  final bool pointsClaimed;

  /// Şu ana kadar sayılan adete göre kazanılacak puan.
  int get pointsEarned => depositedCount * wasteType.pointsPerItem;
}
