import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';

/// SADECE GELİŞTİRME AMAÇLI. Gerçek kutunun üzerinde henüz yazdırılmış bir
/// QR etiketi yok (donanım daha kurulmadı) — bu ekran, test kutusunun
/// QR'ını EKRANDA gösterir. Bir cihazda bu ekranı aç (ör. bilgisayarda
/// Chrome), telefonundan ScanBinPage ile okut — gerçek etiket gelince bu
/// ekrana hiç ihtiyaç kalmayacak, ScanBinPage hiç değişmeden çalışmaya
/// devam edecek.
class ShowBinQrPage extends StatelessWidget {
  const ShowBinQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Kutusu QR Kodu (geliştirme)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data: AppConstants.demoBinId,
                size: 240,
              ),
            ),
            const SizedBox(height: 16),
            Text(AppConstants.demoBinId, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
