import 'package:flutter/material.dart';

import '../../domain/entities/waste_type.dart';

/// WasteType'ın SADECE görsel temsili (renk, ikon). Bilerek domain
/// katmanında değil burada — domain'in Flutter'ı/renkleri bilmesine
/// gerek yok, bu bilgi tamamen sunum (presentation) katmanına ait.
///
/// Renkler rastgele değil: Türkiye'nin "Sıfır Atık" ayrıştırma standardı
/// takip ediliyor — Mavi=Kağıt, Sarı=Plastik, Yeşil=Cam.
extension WasteTypeUiX on WasteType {
  Color get color => switch (this) {
        WasteType.kagit => const Color(0xFF2563EB), // mavi
        WasteType.plastik => const Color(0xFFF5B700), // sarı
        WasteType.cam => const Color(0xFF16A34A), // yeşil
      };

  String get iconAsset => switch (this) {
        WasteType.plastik => 'assets/icons/plastik.png',
        WasteType.kagit => 'assets/icons/kagit.png',
        WasteType.cam => 'assets/icons/cam.png',
      };
}
