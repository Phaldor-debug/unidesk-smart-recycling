import '../../domain/entities/bin_command.dart';
import '../../domain/entities/waste_type.dart';
import '../../domain/repositories/bin_command_repository.dart';
import '../datasources/bin_realtime_datasource.dart';

class BinCommandRepositoryImpl implements BinCommandRepository {
  const BinCommandRepositoryImpl(this._remote);
  final BinRealtimeDataSource _remote;

  @override
  Future<void> publishCommand({
    required String binId,
    required String sessionId,
    required WasteType wasteType,
  }) {
    return _remote.publishCommand(binId: binId, sessionId: sessionId, wasteType: wasteType);
  }

  @override
  Stream<BinCommand?> watchCommand(String binId) => _remote.watchCommand(binId);
}
