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

  DocumentReference<Map<String, dynamic>> get _countersDoc => _firestore
      .collection(FirestorePaths.stats)
      .doc(FirestorePaths.countersDoc);

  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1) Firebase Authentication'da hesabı oluştur.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // 2) Adı Firebase Auth profiline de yaz — Firestore'a erişemeyen
      //    yerlerde (ör. Auth konsolu) kullanıcının kim olduğu görünsün.
      await credential.user!.updateDisplayName(displayName);

      final model = AppUserModel.initial(uid: uid, displayName: displayName);

      // 3) Kaçıncı kayıt olduğunu belirle ("Öncü" rozeti için).
      //    Transaction: iki kişi aynı anda kaydolursa ikisine de aynı
      //    sıra numarası verilmesin.
      final sira = await _firestore.runTransaction<int>((tx) async {
        final snap = await tx.get(_countersDoc);
        final mevcut = (snap.data()?['userCount'] as int?) ?? 0;
        final yeni = mevcut + 1;
        tx.set(_countersDoc, {'userCount': yeni}, SetOptions(merge: true));
        return yeni;
      });

      // 4) Firestore'da bu kullanıcının puan kaydını 0 ile başlat.
      //    .set() ile doc'un id'sini uid yapıyoruz ki her kullanıcının
      //    tam olarak bir kaydı olsun, uid'den kolayca bulunabilsin.
      await _usersCollection.doc(uid).set({
        ...model.toMap(),
        'registrationNo': sira,
      });

      // Kayıt biter bitmez doğrulama bağlantısını yolla — kullanıcı
      // ayrıca bir şey yapmak zorunda kalmasın.
      await credential.user!.sendEmailVerification();

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
        final model = AppUserModel.initial(
          uid: uid,
          displayName: credential.user!.displayName ?? '',
        );
        await _usersCollection.doc(uid).set(model.toMap());
        return model;
      }
      return AppUserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e);
    }
  }

  /// Kullanıcı belgesini canlı dinler. Puan değişince (atık atma,
  /// ödül kullanma) profil ekranı kendiliğinden güncellenir.
  Stream<AppUserModel> watchCurrentUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        // Belge henüz oluşmadıysa (nadir) boş bir profil döndür ki
        // ekran çökmesin.
        return AppUserModel.initial(uid: uid, displayName: '');
      }
      return AppUserModel.fromMap(data);
    });
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e);
    }
  }

  /// reload(): Firebase'in yerel kullanıcı kopyasını sunucudan tazeler.
  /// Bu olmadan, kullanıcı e-postadaki bağlantıya tıklasa bile uygulama
  /// hâlâ "doğrulanmamış" görür.
  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e);
    }
  }
}
