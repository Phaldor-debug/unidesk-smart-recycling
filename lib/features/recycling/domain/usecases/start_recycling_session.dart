import '../entities/waste_type.dart';
import '../repositories/recycling_repository.dart';

class StartRecyclingSession {
  const StartRecyclingSession(this._repository);
  final RecyclingRepository _repository;

  Future<String> call({
    required String uid,
    required String binId,
    required WasteType wasteType,
  }) {
    return _repository.startSession(uid: uid, binId: binId, wasteType: wasteType);
  }
}
