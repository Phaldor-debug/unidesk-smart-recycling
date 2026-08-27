import '../entities/bin_command.dart';
import '../repositories/bin_command_repository.dart';

class WatchBinCommand {
  const WatchBinCommand(this._repository);
  final BinCommandRepository _repository;

  Stream<BinCommand?> call(String binId) => _repository.watchCommand(binId);
}
