import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

/// ESP32'den (RTDB üzerinden) gelen kapak durumu + sayacı Firestore'daki
/// oturuma yansıtır. İkisi TEK bir yazma olarak gider — ayrı ayrı
/// göndermek, "completed" sayaçtan önce varırsa puanın eksik
/// hesaplanmasına yol açıyordu.
class ApplyHardwareUpdate {
  const ApplyHardwareUpdate(this._repository);
  final RecyclingRepository _repository;

  Future<void> call({
    required String sessionId,
    required SessionStatus status,
    required int depositedCount,
  }) {
    return _repository.applyHardwareUpdate(
      sessionId: sessionId,
      status: status,
      depositedCount: depositedCount,
    );
  }
}
