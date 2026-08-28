import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/redemption.dart';
import '../providers/rewards_providers.dart';

/// GEÇİCİ personel ekranı: kod girilir, aktifse hak bilgisi gösterilir,
/// "Kullanıldı" denince bir daha kullanılamaz hale gelir. Gerçek
/// dağıtımda bu, öğrencinin erişemeyeceği ayrı bir giriş/uygulama
/// olmalı — bkz. proje notları.
class StaffVerifyPage extends ConsumerStatefulWidget {
  const StaffVerifyPage({super.key});

  @override
  ConsumerState<StaffVerifyPage> createState() => _StaffVerifyPageState();
}

class _StaffVerifyPageState extends ConsumerState<StaffVerifyPage> {
  final _codeController = TextEditingController();
  Redemption? _found;
  bool _isLoading = false;
  String? _message;
  bool _basarili = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _found = null;
      _message = null;
      _basarili = false;
    });

    final result = await ref.read(findRedemptionByCodeProvider).call(code);

    setState(() {
      _isLoading = false;
      _found = result;
      _message = result == null
          ? 'Bu koda ait kullanılabilir bir hak yok. Kod yanlış olabilir ya da daha önce kullanılmış olabilir.'
          : null;
    });
  }

  Future<void> _markUsed() async {
    final redemption = _found;
    if (redemption == null) return;

    await ref.read(markRedemptionUsedProvider).call(redemption.id);

    setState(() {
      _basarili = true;
      _message = '"${redemption.rewardTitle}" kullanıldı olarak işaretlendi.';
      _found = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yemekhane Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Öğrencinin söylediği 6 haneli kodu gir ve doğrula.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            // Kodlar yalnızca rakamdan oluşuyor; harf girişini baştan
            // engellemek personelin hata yapmasını önlüyor.
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              hintText: '••••••',
              counterText: '',
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _search,
            child: _isLoading
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sorgula'),
          ),
          const SizedBox(height: 28),
          if (_found != null) _GecerliHakKarti(redemption: _found!, onKullan: _markUsed),
          if (_message != null)
            _SonucMesaji(mesaj: _message!, basarili: _basarili),
        ],
      ),
    );
  }
}

class _GecerliHakKarti extends StatelessWidget {
  const _GecerliHakKarti({required this.redemption, required this.onKullan});
  final Redemption redemption;
  final VoidCallback onKullan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      redemption.rewardTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Geçerli — kullanılabilir',
                      style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Buton tam genişlikte ve altta: uzun metinli butonu satırın
          // sağına sıkıştırmak dar ekranlarda taşmaya yol açıyordu.
          FilledButton(
            onPressed: onKullan,
            child: const Text('Kullanıldı Olarak İşaretle'),
          ),
        ],
      ),
    );
  }
}

class _SonucMesaji extends StatelessWidget {
  const _SonucMesaji({required this.mesaj, required this.basarili});
  final String mesaj;
  final bool basarili;

  @override
  Widget build(BuildContext context) {
    final renk = basarili ? AppColors.green : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            basarili ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: renk,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(mesaj)),
        ],
      ),
    );
  }
}
