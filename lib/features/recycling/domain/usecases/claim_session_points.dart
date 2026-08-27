import '../entities/recycling_session.dart';
import '../repositories/recycling_repository.dart';

/// Oturum tamamlandığında kazanılan puanı kullanıcının bakiyesine ekler.
class ClaimSessionPoints {
  const ClaimSessionPoints(this._repository);
  final RecyclingRepository _repository;

  Future<void> call(RecyclingSession session) => _repository.claimPoints(session);
}
