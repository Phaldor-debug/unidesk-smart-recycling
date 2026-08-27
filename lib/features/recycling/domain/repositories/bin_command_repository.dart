import '../entities/bin_command.dart';
import '../entities/waste_type.dart';

/// ESP32 ile Realtime Database üzerinden haberleşme sözleşmesi.
/// Firestore'a dair (puan, sahiplik) HİÇBİR ŞEY burada yok — o iş
/// RecyclingRepository'de. Bu sadece "kutuya canlı komut gönder / kutunun
/// canlı durumunu dinle".
abstract class BinCommandRepository {
  /// Yeni bir oturum başladığında, ESP32'nin göreceği ilk komutu yazar.
  Future<void> publishCommand({
    required String binId,
    required String sessionId,
    required WasteType wasteType,
  });

  /// Bir kutunun canlı komutunu CANLI izler. Kutuda aktif bir şey yoksa null.
  Stream<BinCommand?> watchCommand(String binId);
}
