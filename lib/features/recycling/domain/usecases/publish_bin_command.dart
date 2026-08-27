import '../entities/waste_type.dart';
import '../repositories/bin_command_repository.dart';

class PublishBinCommand {
  const PublishBinCommand(this._repository);
  final BinCommandRepository _repository;

  Future<void> call({
    required String binId,
    required String sessionId,
    required WasteType wasteType,
  }) {
    return _repository.publishCommand(binId: binId, sessionId: sessionId, wasteType: wasteType);
  }
}
