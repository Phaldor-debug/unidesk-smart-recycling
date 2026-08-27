import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/points_balance_model.dart';
import '../models/wallet_transaction_model.dart';

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

  /// Puan geçmişi İKİ ayrı koleksiyondan gelir (kazançlar `sessions`,
  /// harcamalar `redemptions`). Firestore tek sorguda iki koleksiyonu
  /// birleştiremediği için ikisini ayrı ayrı dinleyip burada birleştirip
  /// tarihe göre sıralıyoruz.
  Stream<List<WalletTransactionModel>> watchTransactions(String uid) {
    final controller = StreamController<List<WalletTransactionModel>>();

    // İki akışın SON değerlerini saklıyoruz; hangisi güncellenirse
    // güncellensin, birleşik listeyi baştan üretip yayınlıyoruz.
    var kazanclar = <WalletTransactionModel>[];
    var harcamalar = <WalletTransactionModel>[];

    void yayinla() {
      if (controller.isClosed) return;
      final hepsi = [...kazanclar, ...harcamalar]..sort((a, b) {
          // Tarihi henüz sunucudan dönmemiş (null) kayıtlar en üstte:
          // bunlar az önce oluşturulmuş en yeni işlemlerdir.
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return -1;
          if (b.date == null) return 1;
          return b.date!.compareTo(a.date!); // yeniden eskiye
        });
      controller.add(hepsi);
    }

    // Sadece puanı GERÇEKTEN eklenmiş oturumlar geçmişte görünmeli;
    // yarım kalmış/iptal olmuş oturumlar kullanıcıyı yanıltmasın.
    final kazancAbonesi = _firestore
        .collection(FirestorePaths.sessions)
        .where('uid', isEqualTo: uid)
        .where('pointsClaimed', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      kazanclar = snap.docs.map(WalletTransactionModel.fromSession).toList();
      yayinla();
    }, onError: controller.addError);

    final harcamaAbonesi = _firestore
        .collection(FirestorePaths.redemptions)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      harcamalar = snap.docs.map(WalletTransactionModel.fromRedemption).toList();
      yayinla();
    }, onError: controller.addError);

    // Ekran kapanınca iki dinleyiciyi de bırak — yoksa arka planda
    // Firestore'u dinlemeye devam eder (bellek ve kota israfı).
    controller.onCancel = () async {
      await kazancAbonesi.cancel();
      await harcamaAbonesi.cancel();
    };

    return controller.stream;
  }
}
