import '../entities/recycling_session.dart';
import '../entities/waste_type.dart';

/// Recycling ile ilgili sözleşme. Firebase'e dair bilgi domain'e sızmaz.
abstract class RecyclingRepository {
  /// Yeni bir oturum başlatır (kullanıcı tür seçti). Oluşan oturumun
  /// id'sini döner ki ekran onu izlemeye başlayabilsin.
  Future<String> startSession({
    required String uid,
    required String binId,
    required WasteType wasteType,
  });

  /// Bir oturumu CANLI izler — durumu, sayacı her değiştiğinde yeni
  /// bir RecyclingSession yayınlar.
  Stream<RecyclingSession> watchSession(String sessionId);

  /// Oturum tamamlandığında kazanılan puanı kullanıcıya EKLER.
  /// Aynı oturumdan iki kere çağrılsa bile puan sadece bir kez eklenir.
  Future<void> claimPoints(RecyclingSession session);

  // --- Aşağıdakiler GERÇEKTE ESP32 firmware'inin yapacağı yazmalar. ---
  // Donanım hazır olana kadar UI'daki bir "simülatör" panelinden
  // çağrılacaklar; firmware yazılınca bu metotlar hiç değişmeyecek,
  // sadece onları ESP32 tetikleyecek.

  /// Kapağın açıldığını / kapandığını bildirir.
  Future<void> updateStatus(String sessionId, SessionStatus status);

  /// IR sensörün bir adet daha algıladığını bildirir (sayaç +1).
  /// Debug simülatöründeki "+1 Adet Algıla" butonu bunu kullanır.
  Future<void> incrementDepositedCount(String sessionId);

  /// ESP32'den (RTDB üzerinden) gelen durumu Firestore'a TEK SEFERDE yazar.
  ///
  /// Neden tek metot: status ve depositedCount'u iki ayrı yazma olarak
  /// göndermek YARIŞ DURUMU yaratıyordu — "completed" önce varırsa, puan
  /// henüz güncellenmemiş (eski) sayaçla hesaplanıp kilitleniyordu ve
  /// kullanıcı hak ettiği puanı alamıyordu. Tek update ile ikisi aynı
  /// anda görünür olur, bu imkânsız hale gelir.
  Future<void> applyHardwareUpdate({
    required String sessionId,
    required SessionStatus status,
    required int depositedCount,
  });
}
