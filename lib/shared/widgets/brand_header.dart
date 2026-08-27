import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Giriş ve kayıt ekranlarının tepesindeki marka başlığı: uygulama
/// ikonunun aynısı (yeşil daire + altın halka + "Ü") ve alt yazı.
/// Kod ile çiziliyor — ayrı bir görsel dosyasına bağımlı değil, her
/// ekran boyutunda net görünür.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 3),
              ),
              child: const Center(
                child: Text(
                  'Ü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Ünidesk',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
