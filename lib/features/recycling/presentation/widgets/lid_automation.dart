import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recycling_session.dart';
import '../providers/recycling_providers.dart';

/// Kapak zamanlamasının uygulama tarafındaki karşılığı.
///
/// ÖNEMLİ AYRIM: gerçek sistemde bu zamanlamayı ESP32 yapıyor —
/// firmware `pending` komutunu görünce servoyu kendi açıyor ve
/// `BOSTA_KALMA_SURESI_MS` (5 sn) boyunca yeni algılama olmazsa
/// kendi kapatıyor. Uygulama bu kararları VERMİYOR, sadece sonucu
/// gösteriyor.
///
/// Bu sınıfın iki işi var:
///   1. Her derlemede: kapağın ne zaman kapanacağını kullanıcıya
///      geri sayımla gösterir (aceleye getirsin, kapak boşuna açık
///      kalmasın).
///   2. Sadece debug'da: donanım yokken firmware'in yaptığı geçişleri
///      (otomatik açma / boşta kalınca kapatma) taklit eder ki test
///      ettiğin akış gerçekte olacakla aynı olsun.
class LidAutomation extends ConsumerStatefulWidget {
  const LidAutomation({
    super.key,
    required this.session,
    required this.child,
  });

  final RecyclingSession session;

  /// Geri sayım değerini alan gövde. `null` ise kapak açık değil.
  final Widget Function(BuildContext context, int? kalanSaniye) child;

  /// Firmware'deki BOSTA_KALMA_SURESI_MS ile AYNI olmalı.
  static const Duration bostaKalmaSuresi = Duration(seconds: 5);

  /// Servonun komutu görüp kapağı açması için geçen gerçekçi gecikme.
  /// Yalnızca simülasyonda kullanılır.
  static const Duration acilmaGecikmesi = Duration(milliseconds: 1200);

  @override
  ConsumerState<LidAutomation> createState() => _LidAutomationState();
}

class _LidAutomationState extends ConsumerState<LidAutomation> {
  /// Sayacın en son değiştiği an — geri sayım buradan hesaplanıyor.
  DateTime _sonHareket = DateTime.now();

  /// Ekranı saniyede bir tazeleyen zamanlayıcı.
  Timer? _tik;

  /// Simülasyonda kapağın açılmasını bekleyen zamanlayıcı.
  Timer? _acmaZamanlayicisi;

  int? _kalanSaniye;

  @override
  void initState() {
    super.initState();
    _durumaGoreAyarla(oncekiSayac: null, oncekiDurum: null);
  }

  @override
  void didUpdateWidget(covariant LidAutomation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _durumaGoreAyarla(
      oncekiSayac: oldWidget.session.depositedCount,
      oncekiDurum: oldWidget.session.status,
    );
  }

  void _durumaGoreAyarla({int? oncekiSayac, SessionStatus? oncekiDurum}) {
    final session = widget.session;

    // Yeni bir atık algılandıysa boşta kalma süresi baştan başlar.
    if (oncekiSayac != null && session.depositedCount != oncekiSayac) {
      _sonHareket = DateTime.now();
    }
    // Kapak yeni açıldıysa da sayaç sıfırlanır.
    if (oncekiDurum != SessionStatus.lidOpen && session.status == SessionStatus.lidOpen) {
      _sonHareket = DateTime.now();
    }

    switch (session.status) {
      case SessionStatus.pending:
        _tikDurdur();
        _kalanSaniye = null;
        // Simülasyon: firmware'in servoyu açması gibi, kısa bir
        // gecikmeden sonra kapağı aç.
        if (kDebugMode) {
          _acmaZamanlayicisi ??= Timer(LidAutomation.acilmaGecikmesi, () {
            _acmaZamanlayicisi = null;
            if (!mounted) return;
            if (widget.session.status != SessionStatus.pending) return;
            ref
                .read(updateSessionStatusProvider)
                .call(widget.session.id, SessionStatus.lidOpen);
          });
        }
      case SessionStatus.lidOpen:
        _tikBaslat();
      case SessionStatus.completed:
        _tikDurdur();
        _kalanSaniye = null;
    }
  }

  void _tikBaslat() {
    _tik ??= Timer.periodic(const Duration(milliseconds: 250), (_) => _tikAt());
    _tikAt();
  }

  void _tikDurdur() {
    _tik?.cancel();
    _tik = null;
  }

  void _tikAt() {
    if (!mounted) return;
    final gecen = DateTime.now().difference(_sonHareket);
    final kalan = LidAutomation.bostaKalmaSuresi - gecen;
    final kalanSaniye = kalan.inMilliseconds <= 0 ? 0 : (kalan.inMilliseconds / 1000).ceil();

    if (kalanSaniye != _kalanSaniye) {
      setState(() => _kalanSaniye = kalanSaniye);
    }

    // Simülasyon: süre dolduysa firmware'in yapacağı gibi kapat.
    // Gerçek donanımda bu satır çalışmaz; kapatma kararını ESP32 verir
    // ve uygulama sadece sonucu görür.
    if (kDebugMode && kalanSaniye == 0 && widget.session.status == SessionStatus.lidOpen) {
      _tikDurdur();
      ref
          .read(updateSessionStatusProvider)
          .call(widget.session.id, SessionStatus.completed);
    }
  }

  @override
  void dispose() {
    _tikDurdur();
    _acmaZamanlayicisi?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child(context, _kalanSaniye);
}
