import 'package:flutter/material.dart';

import '../../domain/entities/redemption.dart';

/// Kod üretildikten hemen sonra gösterilen ekran. Kullanıcı bu kodu
/// yemekhanede söyler/gösterir; personel StaffVerifyPage'den sorgular.
class RedemptionCodePage extends StatelessWidget {
  const RedemptionCodePage({super.key, required this.redemption});
  final Redemption redemption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(redemption.rewardTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text('Hakkın oluşturuldu! Bu kodu yemekhanede göster:'),
              const SizedBox(height: 24),
              // Kodu büyük ve boşluklu göster — yemekhanede uzaktan
              // okunması/okunması kolay olsun diye.
              Text(
                redemption.code.split('').join(' '),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4),
              ),
              const SizedBox(height: 24),
              const Text(
                'Not: Kod yalnızca bir kez kullanılabilir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
