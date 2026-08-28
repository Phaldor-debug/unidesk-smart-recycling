import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/redemption.dart';

/// Kod üretildikten hemen sonra gösterilen ekran. Kullanıcı bu kodu
/// yemekhanede söyler/gösterir; personel StaffVerifyPage'den sorgular.
class RedemptionCodePage extends StatelessWidget {
  const RedemptionCodePage({super.key, required this.redemption});
  final Redemption redemption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gold,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                redemption.rewardTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hakkın hazır. Bu kodu yemekhanede göster.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 32),
              _KodKarti(kod: redemption.code),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: Colors.white70),
                  const SizedBox(width: 6),
                  const Text(
                    'Yalnızca bir kez kullanılabilir',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.gold,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tamam'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kodlarım sekmesinden tekrar görebilirsin',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kodu büyük, boşluklu ve kopyalanabilir şekilde gösterir —
/// yemekhanede uzaktan okunması kolay olsun diye.
class _KodKarti extends StatelessWidget {
  const _KodKarti({required this.kod});
  final String kod;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              kod.split('').join(' '),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Color(0xFF1F1300),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: const Text('Kodu kopyala'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: kod));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kod kopyalandı')),
              );
            },
          ),
        ],
      ),
    );
  }
}
