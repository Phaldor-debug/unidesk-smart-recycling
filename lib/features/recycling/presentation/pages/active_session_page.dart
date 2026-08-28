import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recycling_session.dart';
import '../../domain/entities/waste_type.dart'; // WasteTypeX (.label, .pointsPerItem) için
import '../../../badges/presentation/providers/badge_providers.dart';
import '../providers/recycling_providers.dart';
import '../providers/session_auto_close_provider.dart';
import '../utils/waste_type_ui.dart';
import '../widgets/lid_automation.dart';

/// Bir oturumu CANLI izleyen ekran. ESP32 (şimdilik simülatör) durumu
/// her değiştirdiğinde bu ekran KENDİLİĞİNDEN güncellenir — sayfayı
/// yenilemeye gerek yok, StreamProvider bunu otomatik sağlıyor.
///
/// Uygulamanın "an"ı burası: kullanıcı kutunun başında, attığı her şeyin
/// anında sayıldığını görmeli. Bu yüzden ekran tamamen atık türünün
/// rengine boyanıyor ve sayaç merkezde büyük duruyor.
class ActiveSessionPage extends ConsumerStatefulWidget {
  const ActiveSessionPage({super.key, required this.sessionId, required this.binId});
  final String sessionId;
  final String binId;

  @override
  ConsumerState<ActiveSessionPage> createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends ConsumerState<ActiveSessionPage> {
  /// Notifier'ı BİR KEZ alıp saklıyoruz.
  ///
  /// dispose() içinde `ref.read(...)` çağırmak Riverpod'da hata fırlatıyor
  /// ("Using ref when a widget is about to or has been unmounted is
  /// unsafe"). Bu yüzden ekrandan çıkış bildirimi hiç ulaşmıyordu:
  /// oturum "ekranda açık" işaretli kalıyor, ana sayfadaki kapatıcı da
  /// ona dokunmuyordu — oturum sonsuza kadar askıda kalıyordu.
  /// Kütüphanenin önerdiği çözüm: state alanında sakla.
  late final SessionAutoClose _oturumKapatici;

  @override
  void initState() {
    super.initState();
    _oturumKapatici = ref.read(sessionAutoCloseProvider.notifier);
    // Ekran açık olduğu sürece otomatik kapatma devre dışı.
    _oturumKapatici.ekranaGirildi(widget.sessionId);
  }

  @override
  void dispose() {
    // Kullanıcı ekrandan çıktı: oturumu hemen bitir, o ana kadarki
    // puanı yaz.
    _oturumKapatici.ekrandanCikildi(widget.sessionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.sessionId;
    final binId = widget.binId;
    final sessionAsync = ref.watch(activeSessionProvider(sessionId));

    // Oturum 'completed' durumuna geçtiği ve puan henüz eklenmediği anda,
    // TAM OLARAK BİR KEZ puanı kullanıcıya ekle. ref.listen sadece DEĞİŞİM
    // olduğunda çalışır (build her tetiklendiğinde değil), bu yüzden
    // tekrar tekrar çağrılma riski yok; datasource'taki transaction da
    // zaten ikinci bir çağrıyı güvenle görmezden gelir.
    ref.listen(activeSessionProvider(sessionId), (previous, next) {
      final session = next.value;
      if (session != null &&
          session.status == SessionStatus.completed &&
          !session.pointsClaimed) {
        // Puan yazıldıktan SONRA rozet kontrolü: yeni istatistiklerle
        // hak edilen rozet var mı diye bakar.
        ref.read(claimSessionPointsProvider).call(session).then(
              (_) => ref.read(badgeCheckerProvider.notifier).kontrolEt(),
            );
      }
    });

    // --- ESP32 köprüsü ---
    // Realtime Database'deki canlı komutu (kapak durumu, sayaç) dinleyip
    // Firestore'daki oturuma YANSITIYORUZ. Böylece ekranın geri kalanı,
    // verinin debug butonundan mı yoksa gerçek ESP32'den mi geldiğini
    // hiç bilmez — ikisi de aynı Firestore alanlarını günceller.
    ref.listen(binCommandProvider(binId), (previous, next) {
      final command = next.value;
      final currentSession = ref.read(activeSessionProvider(sessionId)).value;
      if (command == null || currentSession == null) return;
      // Bu kutunun komutu BAŞKA bir oturuma aitse (ör. önceki kullanıcıdan
      // kalan veri) yok say — sadece kendi oturumumuzu dinliyoruz.
      if (command.sessionId != sessionId) return;

      // Durum ve sayacı TEK bir yazmada gönderiyoruz. Ayrı ayrı
      // gönderilseydi "completed" sayaçtan önce varabilir, puan eski
      // sayaçla hesaplanıp kilitlenebilirdi (kullanıcı puanını kaybederdi).
      final degisti = command.status != currentSession.status ||
          command.depositedCount != currentSession.depositedCount;
      if (!degisti) return;

      ref.read(applyHardwareUpdateProvider).call(
            sessionId: sessionId,
            status: command.status,
            depositedCount: command.depositedCount,
          );
    });

    return sessionAsync.when(
      data: (session) => _SessionScaffold(session: session),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Bir sorun oldu:\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class _SessionScaffold extends StatelessWidget {
  const _SessionScaffold({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context) {
    final renk = session.wasteType.color;
    final bitti = session.status == SessionStatus.completed;

    return Scaffold(
      // Ekranın tamamı atık türünün rengine boyanıyor: kullanıcı hangi
      // bölmeye attığını renkten de anlıyor, kutunun etiketiyle eşleşiyor.
      backgroundColor: renk,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(session.wasteType.label),
      ),
      body: SafeArea(
        // Kapak zamanlamasını LidAutomation yönetiyor: geri sayımı verir,
        // debug'da firmware'in aç/kapat geçişlerini de taklit eder.
        child: LidAutomation(
          session: session,
          child: (context, kalanSaniye) => Column(
            children: [
              Expanded(
                child: Center(
                  child: bitti
                      ? _TamamlandiGorunumu(session: session)
                      : _SayacGorunumu(session: session, kalanSaniye: kalanSaniye),
                ),
              ),
              if (kDebugMode) _SimulatorPanel(session: session),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oturum sürerken: ortada büyük sayaç, altında durum mesajı.
class _SayacGorunumu extends StatelessWidget {
  const _SayacGorunumu({required this.session, required this.kalanSaniye});
  final RecyclingSession session;

  /// Kapak kapanmadan kalan süre. Kapak açık değilse null.
  final int? kalanSaniye;

  @override
  Widget build(BuildContext context) {
    final acik = session.status == SessionStatus.lidOpen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NabizHalkasi(
          aktif: acik,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              // Sayaç her arttığında yumuşak bir geçişle değişsin —
              // kullanıcı atışının sayıldığını hissetsin.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  '${session.depositedCount}',
                  key: ValueKey(session.depositedCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 84,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'adet atıldı',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 36),
        _DurumSatiri(status: session.status, kalanSaniye: kalanSaniye),
        const SizedBox(height: 14),
        Text(
          'Şu ana kadar +${session.pointsEarned} puan',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Kapak açıkken halkanın etrafında yavaşça büyüyüp sönen bir dalga —
/// "sistem seni bekliyor, atabilirsin" hissini veriyor.
class _NabizHalkasi extends StatefulWidget {
  const _NabizHalkasi({required this.aktif, required this.child});
  final bool aktif;
  final Widget child;

  @override
  State<_NabizHalkasi> createState() => _NabizHalkasiState();
}

class _NabizHalkasiState extends State<_NabizHalkasi> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.aktif) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _NabizHalkasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aktif && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.aktif && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hareket azaltma tercihi açıksa animasyonu hiç kurmuyoruz.
    final hareketAzalt = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.aktif || hareketAzalt) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180 + (90 * t),
              height: 180 + (90 * t),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: (1 - t) * 0.35),
                  width: 2,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _DurumSatiri extends StatelessWidget {
  const _DurumSatiri({required this.status, this.kalanSaniye});
  final SessionStatus status;
  final int? kalanSaniye;

  @override
  Widget build(BuildContext context) {
    // Kapak açıkken kalan süreyi metnin içinde gösteriyoruz: kullanıcı
    // kapağın kendiliğinden kapanacağını bilsin, boşuna beklemesin.
    final acikMetin = kalanSaniye != null && kalanSaniye! > 0
        ? 'Atığını at — $kalanSaniye sn'
        : 'Kapak açık — atığını atabilirsin';

    final (metin, ikon) = switch (status) {
      SessionStatus.pending => ('Kapak açılıyor...', Icons.hourglass_top_rounded),
      SessionStatus.lidOpen => (acikMetin, Icons.lock_open_rounded),
      SessionStatus.completed => ('Tamamlandı', Icons.check_circle_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            metin,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (status == SessionStatus.pending) ...[
            const SizedBox(width: 10),
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

/// Oturum bitince: kazanılan puanı öne çıkaran kutlama görünümü.
class _TamamlandiGorunumu extends StatelessWidget {
  const _TamamlandiGorunumu({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: 54,
              color: session.wasteType.color,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Teşekkürler!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${session.depositedCount} adet ${session.wasteType.label.toLowerCase()} geri dönüşüme kazandırdın',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+${session.pointsEarned} puan',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: session.wasteType.color,
              ),
              // Bu ekran ana sayfadan iki adım derinde açıldığı için
              // (QR -> tür seçimi -> oturum) ikisini birden kapatıyoruz.
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Bitir'),
            ),
          ),
        ],
      ),
    );
  }
}

/// ESP32 firmware'i yazılana kadar donanımın yapacağı 3 olayı elle
/// tetiklemeyi sağlayan buton grubu. Bastığın her buton, firmware'in
/// ileride yazacağı TAM OLARAK aynı veriyi yazıyor — yani bu ekranın
/// geri kalanı hiç değişmeden gerçek donanıma geçilecek.
class _SimulatorPanel extends ConsumerWidget {
  const _SimulatorPanel({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'DONANIM SİMÜLATÖRÜ · kapak otomatik, sen sadece at',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Kapağı açma/kapatma butonları KALDIRILDI: bunları artık
              // LidAutomation otomatik yapıyor, tıpkı gerçek ESP32 gibi.
              // Geriye tek insan hareketi kalıyor — atığı kutuya atmak.
              _SimButon(
                etiket: 'Atık At (+1)',
                aktif: session.status == SessionStatus.lidOpen,
                onTap: () => ref.read(incrementDepositedCountProvider).call(session.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimButon extends StatelessWidget {
  const _SimButon({required this.etiket, required this.aktif, required this.onTap});
  final String etiket;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: aktif ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
        side: BorderSide(color: Colors.white.withValues(alpha: aktif ? 0.6 : 0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(etiket),
    );
  }
}
