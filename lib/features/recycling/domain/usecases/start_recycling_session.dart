import '../entities/waste_type.dart';
import '../repositories/recycling_repository.dart';

class StartRecyclingSession {
  const StartRecyclingSession(this._repository);
  final RecyclingRepository _repository;

  /// Oturum yazılmadan önce kimliğini üretir.
  String yeniKimlik() => _repository.yeniOturumKimligi();

  Future<void> call({
    required String sessionId,
    required String uid,
    required String binId,
    required WasteType wasteType,
  }) {
    return _repository.startSession(
      sessionId: sessionId,
      uid: uid,
      binId: binId,
      wasteType: wasteType,
    );
  }
}
