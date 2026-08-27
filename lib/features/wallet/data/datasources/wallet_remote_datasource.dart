import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/points_balance_model.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<PointsBalanceModel> watchPointsBalance(String uid) {
    // .snapshots(): Firestore'un canlı dinleyicisi. Belge her değiştiğinde
    // (biz değiştirsek de, ileride ESP32/Cloud Function değiştirse de)
    // otomatik olarak yeni bir değer yayınlar — sayfayı yenilemeye gerek yok.
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((snapshot) => PointsBalanceModel.fromMap(snapshot.data()));
  }
}
