import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../models/app_user_model.dart';

/// Firebase ile DOĞRUDAN konuşan tek katman. Sadece repository burayı
/// çağırır — başka hiçbir dosya FirebaseAuth/Firestore'u görmez.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._auth, this._firestore);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestorePaths.users);

  Future<AppUserModel> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // 1) Firebase Authentication'da hesabı oluştur.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final model = AppUserModel.initial(uid: uid, email: email);

      // 2) Firestore'da bu kullanıcının puan kaydını 0 ile başlat.
      //    .set() ile doc'un id'sini uid yapıyoruz ki her kullanıcının
      //    tam olarak bir kaydı olsun, uid'den kolayca bulunabilsin.
      await _usersCollection.doc(uid).set(model.toMap());

      return model;
    } on FirebaseAuthException catch (e) {
      // Ham Firebase hatasını, ekranda gösterilebilecek Türkçe mesaja çeviriyoruz.
      throw AppException.fromFirebaseAuth(e);
    }
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Giriş yapınca Firestore'daki GÜNCEL puanı çekiyoruz
      // (Auth kendi başına puanı bilmez, o bilgi Firestore'da).
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) {
        // Firestore kaydı bir sebeple yoksa (nadir), 0 puanla oluştur.
        final model = AppUserModel.initial(uid: uid, email: email);
        await _usersCollection.doc(uid).set(model.toMap());
        return model;
      }
      return AppUserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e);
    }
  }

  Future<void> signOut() => _auth.signOut();
}
