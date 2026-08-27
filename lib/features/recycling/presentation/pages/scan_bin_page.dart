import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_constants.dart';

/// Kutunun üzerindeki QR etiketini telefon kamerasıyla okur ve okunan
/// metni (binId) Navigator.pop ile çağıran ekrana döndürür.
class ScanBinPage extends StatefulWidget {
  const ScanBinPage({super.key});

  @override
  State<ScanBinPage> createState() => _ScanBinPageState();
}

class _ScanBinPageState extends State<ScanBinPage> {
  // Kamera aynı kareyi defalarca okuyup pop'u birden çok kez tetiklemesin
  // diye bir kilit — ilk geçerli okumadan sonra hepsini yok sayıyoruz.
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    // Chrome'da (masaüstünde) geliştirirken kamerayı hiç BAŞLATMIYORUZ —
    // MobileScanner widget'ı ekrana gelir gelmez tarayıcıdan izin istiyor,
    // bu da hızlı test döngüsünü yavaşlatıyordu. Telefonda (kIsWeb false)
    // veya release modda davranış hiç değişmiyor, gerçek kamera açılır.
    final skipCamera = kDebugMode && kIsWeb;

    return Scaffold(
      appBar: AppBar(title: const Text('Kutunun QR Kodunu Okut')),
      body: skipCamera ? _DesktopTestBody(onSkip: () => Navigator.of(context).pop(AppConstants.demoBinId)) : _CameraBody(onDetect: _onDetect),
    );
  }
}

class _CameraBody extends StatelessWidget {
  const _CameraBody({required this.onDetect});
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          onDetect: onDetect,
          // Kamera izni reddedilirse ya da cihazda kamera yoksa,
          // varsayılan (İngilizce) hata yerine anlaşılır bir mesaj göster.
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Kameraya erişilemedi.\n'
                'Telefonun ayarlarından bu uygulamaya kamera izni verdiğinden emin ol.\n\n'
                'Teknik detay: ${error.errorCode}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        // Ortada basit bir çerçeve — kullanıcıya nereye tutması
        // gerektiğini gösteren görsel ipucu, tarama mantığına dahil değil.
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Text(
            'QR kodu çerçevenin içine getir',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

/// Chrome'da geliştirirken kamera yerine gösterilen basit ekran.
class _DesktopTestBody extends StatelessWidget {
  const _DesktopTestBody({required this.onSkip});
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.desktop_windows_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Chrome\'da kamera taraması geliştirme için kapalı.\n'
              'Gerçek tarama telefonda çalışır.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onSkip,
              child: const Text('🔧 Test kutusuyla devam et'),
            ),
          ],
        ),
      ),
    );
  }
}
