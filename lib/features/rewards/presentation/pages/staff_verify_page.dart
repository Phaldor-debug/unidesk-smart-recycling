import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    });

    final result = await ref.read(findRedemptionByCodeProvider).call(code);

    setState(() {
      _isLoading = false;
      _found = result;
      _message = result == null ? 'Aktif bir hak bulunamadı (yanlış kod veya zaten kullanılmış).' : null;
    });
  }

  Future<void> _markUsed() async {
    final redemption = _found;
    if (redemption == null) return;

    await ref.read(markRedemptionUsedProvider).call(redemption.id);

    setState(() {
      _message = '"${redemption.rewardTitle}" kullanıldı olarak işaretlendi.';
      _found = null;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yemekhane Paneli')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Öğrencinin söylediği 6 haneli kod'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isLoading ? null : _search,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sorgula'),
            ),
            const SizedBox(height: 24),
            if (_found != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    // ListTile'ın title+subtitle+trailing'i tek satıra sıkıştırma
                    // davranışı, uzun buton metniyle (dar telefon ekranlarında)
                    // üst üste binmeye sebep oluyordu. Bunun yerine bilgi üstte,
                    // buton ALTTA ve TAM GENİŞLİKTE — hiçbir ekran genişliğinde
                    // sıkışmaz.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_found!.rewardTitle,
                                    style: Theme.of(context).textTheme.titleMedium),
                                const Text('Aktif — kullanılabilir'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _markUsed,
                        child: const Text('Kullanıldı Olarak İşaretle'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message!, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
