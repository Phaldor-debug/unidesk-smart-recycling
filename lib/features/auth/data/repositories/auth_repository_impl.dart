import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// domain'in istediği sözleşmeyi (AuthRepository), datasource'u kullanarak
/// gerçekleştirir. Şu an ince bir katman gibi görünüyor ama yarın
/// "önce yerel cache'e bak, yoksa Firebase'e sor" gibi mantık eklesek
/// bile domain ve presentation hiç etkilenmez.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _remote.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _remote.signIn(email: email, password: password);
  }

  @override
  Stream<AppUser> watchCurrentUser(String uid) => _remote.watchCurrentUser(uid);

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _remote.sendPasswordResetEmail(email);
  }
}
