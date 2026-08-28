import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/big_action_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/waste_type.dart';
import '../providers/recycling_providers.dart';
import '../providers/session_auto_close_provider.dart';
import '../utils/waste_type_ui.dart';
import 'active_session_page.dart';

/// Kullanıcının atık türünü seçtiği ekran. `binId`, bir önceki adımda
/// ScanBinPage ile okutulan kutu QR'ından geliyor — hangi kutu, hangi
/// öğrencinin oturumu olduğunu bu sayede birbirinden ayırıyoruz.
class SelectWastePage extends ConsumerWidget {
  const SelectWastePage({super.key, required this.binId});
  final String binId;

  Future<void> _startSession(BuildContext context, WidgetRef ref, WasteType type) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return; // AuthGate zaten girişsiz buraya gelmeyi engeller.

    final sessionId = await ref.read(startRecyclingSessionProvider).call(
          uid: uid,
          binId: binId,
          wasteType: type,
        );

    // Oturumu HEMEN korumaya alıyoruz. Aksi halde Firestore'dan gelen
    // "devam eden oturum" bildirimi ana sayfaya, kullanıcı daha atma
    // ekranına varmadan ulaşıp oturumu kapatabilirdi.
    ref.read(sessionAutoCloseProvider.notifier).ekranaGirildi(sessionId);

    // Firestore'daki kalıcı kayıttan SONRA, ESP32'nin izleyeceği canlı
    // komutu Realtime Database'e yazıyoruz. Gerçek donanım henüz yokken
    // bile bu yazma zararsız — kimse dinlemiyorsa hiçbir şey olmaz.
    await ref.read(publishBinCommandProvider).call(
          binId: binId,
          sessionId: sessionId,
          wasteType: type,
        );

    if (!context.mounted) return; // async çağrıdan sonra widget hâlâ ekranda mı, kontrol.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActiveSessionPage(sessionId: sessionId, binId: binId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ne atıyorsun?')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: WasteType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BigActionCard(
              color: type.color,
              iconAsset: type.iconAsset,
              title: type.label,
              subtitle: '+${type.pointsPerItem} puan / adet',
              onTap: () => _startSession(context, ref, type),
            ),
          );
        }).toList(),
      ),
    );
  }
}
