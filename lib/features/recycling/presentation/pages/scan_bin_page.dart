import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Kutunun QR Kodunu Okut')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _onDetect,
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
      ),
    );
  }
}
