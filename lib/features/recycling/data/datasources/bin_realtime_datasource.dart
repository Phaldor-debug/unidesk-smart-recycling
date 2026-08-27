import 'package:firebase_database/firebase_database.dart';

import '../../domain/entities/waste_type.dart';
import '../models/bin_command_model.dart';

/// RTDB ile DOĞRUDAN konuşan tek katman — Firestore'a hiç dokunmaz.
/// ESP32 firmware'i, burada yazdığımızın BİREBİR aynısını okuyup/yazacak.
class BinRealtimeDataSource {
  BinRealtimeDataSource(this._database);
  final FirebaseDatabase _database;

  DatabaseReference _commandRef(String binId) => _database.ref('bin_commands/$binId');

  Future<void> publishCommand({
    required String binId,
    required String sessionId,
    required WasteType wasteType,
  }) {
    // .set(): o yoldaki TÜM veriyi bu Map ile değiştirir (Firestore'un
    // .set() ile aynı mantık) — eski bir oturumdan kalan veri olsa bile
    // temiz bir başlangıç garanti edilir.
    return _commandRef(binId).set(
      BinCommandModel.initialMap(sessionId: sessionId, wasteType: wasteType),
    );
  }

  Stream<BinCommandModel?> watchCommand(String binId) {
    // .onValue: RTDB'nin canlı dinleyicisi — Firestore'daki .snapshots()'ın
    // karşılığı. event.snapshot.value, o yoldaki HAM veriyi (Map/JSON) verir.
    return _commandRef(binId).onValue.map((event) {
      final value = event.snapshot.value;
      return BinCommandModel.fromMap(value as Map<dynamic, dynamic>?);
    });
  }
}
