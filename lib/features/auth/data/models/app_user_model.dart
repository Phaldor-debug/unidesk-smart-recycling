import '../../domain/entities/app_user.dart';

/// AppUser'ın Firestore'a yazılıp okunabilir hali. domain katmanındaki
/// AppUser'ı GENİŞLETİR (extends) — yani her yerde AppUser gibi kullanılabilir,
/// üstüne Firestore'a çevirme yeteneği eklenmiş olur.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.displayName,
    required super.points,
  });

  /// Yeni kayıt olan bir kullanıcı için başlangıç durumu: 0 puan.
  factory AppUserModel.initial({
    required String uid,
    required String displayName,
  }) {
    return AppUserModel(uid: uid, displayName: displayName, points: 0);
  }

  /// Firestore'dan gelen Map'i AppUserModel'e çevirir.
  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      uid: map['uid'] as String? ?? '',
      // Bu alan eklenmeden önce kaydolmuş kullanıcılarda boş gelir.
      displayName: map['displayName'] as String? ?? '',
      points: map['points'] as int? ?? 0,
    );
  }

  /// Firestore'a yazarken kullanılacak Map.
  /// E-posta bilerek yazılmıyor — bkz. AppUser sınıfındaki açıklama.
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'displayName': displayName, 'points': points};
  }
}
