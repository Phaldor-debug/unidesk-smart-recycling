// cloud_firestore paketi: Firestore veritabanı sınıflarını (FirebaseFirestore) getirir.
import 'package:cloud_firestore/cloud_firestore.dart';
// firebase_auth paketi: kimlik doğrulama sınıflarını (FirebaseAuth, User) getirir.
import 'package:firebase_auth/firebase_auth.dart';
// Riverpod: Provider, ref gibi durum yönetimi araçlarını getirir.
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
