// cloud_firestore paketi: Firestore veritabanı sınıflarını (FirebaseFirestore) getirir.
import 'package:cloud_firestore/cloud_firestore.dart';
// firebase_auth paketi: kimlik doğrulama sınıflarını (FirebaseAuth, User) getirir.
import 'package:firebase_auth/firebase_auth.dart';
// firebase_core: Firebase.app() burada.
import 'package:firebase_core/firebase_core.dart';
// firebase_database: ESP32 ile canlı haberleşeceğimiz Realtime Database.
import 'package:firebase_database/firebase_database.dart';
// Riverpod: Provider, ref gibi durum yönetimi araçlarını getirir.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// FirebaseAuth'un tekil (singleton) örneğini bir provider içine sarar.
/// Böylece kodun hiçbir yerinde doğrudan `FirebaseAuth.instance` yazmayız;
/// hep `ref.watch(firebaseAuthProvider)` deriz. Bu, testte sahte (mock) Auth
/// koyabilmemizi sağlar.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Aynı mantık Firestore için. Veritabanına erişen her datasource
/// bu provider üzerinden Firestore örneğini alacak.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Realtime Database örneği. `instanceFor` kullanıyoruz çünkü RTDB'nin
/// bölgesi (europe-west1) Firestore'dan farklı olabiliyor — adres
/// firebase_options.dart'ta otomatik gelmez, elle vermemiz gerekiyor.
final realtimeDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: AppConstants.rtdbUrl,
  );
});
