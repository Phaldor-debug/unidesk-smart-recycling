import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class WatchCurrentUser {
  const WatchCurrentUser(this._repository);
  final AuthRepository _repository;

  Stream<AppUser> call(String uid) => _repository.watchCurrentUser(uid);
}
