import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/waste_type.dart';
import '../providers/recycling_providers.dart';
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
            child: _WasteTypeCard(
              type: type,
              onTap: () => _startSession(context, ref, type),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Büyük, renkli, basılınca hafifçe küçülen interaktif materyal kartı.
class _WasteTypeCard extends StatefulWidget {
  const _WasteTypeCard({required this.type, required this.onTap});
  final WasteType type;
  final VoidCallback onTap;

  @override
  State<_WasteTypeCard> createState() => _WasteTypeCardState();
}

class _WasteTypeCardState extends State<_WasteTypeCard> {
  // Parmak kartın üzerindeyken true olur — kart hafifçe küçülür,
  // "basılabilir" bir cisim gibi hissettirir.
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Kartın kendi renginden yumuşak bir gölge — düz bir gölgeden
              // çok daha "canlı"/premium görünüyor.
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            children: [
              // Materyalin kendi ikonu, hafif yarı saydam bir daire üzerinde
              // — "rozet" hissini app ikonuyla tutarlı tutuyor.
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset(widget.type.iconAsset, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type.label,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${widget.type.pointsPerItem} puan / adet',
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
