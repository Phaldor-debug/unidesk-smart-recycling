import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

/// Bu iki use case, GERÇEKTE ESP32 firmware'inin çağıracağı işlemleri
/// temsil eder (kapağı aç/kapat bildirimi, bir adet sayıldı bildirimi).
/// Donanım hazır olana kadar bunları geliştirme ekranındaki bir
/// "simülatör" panelinden biz tetikleyeceğiz. Firmware yazılınca bu
/// dosyaya hiç dokunulmayacak — sadece onu tetikleyen taraf değişecek.
class UpdateSessionStatus {
  const UpdateSessionStatus(this._repository);
  final RecyclingRepository _repository;

  Future<void> call(String sessionId, SessionStatus status) {
    return _repository.updateStatus(sessionId, status);
  }
}

class IncrementDepositedCount {
  const IncrementDepositedCount(this._repository);
  final RecyclingRepository _repository;

  Future<void> call(String sessionId) => _repository.incrementDepositedCount(sessionId);
}
