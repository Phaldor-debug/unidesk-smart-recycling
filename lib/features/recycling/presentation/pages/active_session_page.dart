import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recycling_session.dart';
import '../../domain/entities/waste_type.dart'; // WasteTypeX (.label, .pointsPerItem) için
import '../providers/recycling_providers.dart';

/// Bir oturumu CANLI izleyen ekran. ESP32 (şimdilik simülatör) durumu
/// her değiştirdiğinde bu ekran KENDİLİĞİNDEN güncellenir — sayfayı
/// yenilemeye gerek yok, StreamProvider bunu otomatik sağlıyor.
class ActiveSessionPage extends ConsumerWidget {
  const ActiveSessionPage({super.key, required this.sessionId, required this.binId});
  final String sessionId;
  final String binId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(activeSessionProvider(sessionId));

    // Oturum 'completed' durumuna geçtiği ve puan henüz eklenmediği anda,
    // TAM OLARAK BİR KEZ puanı kullanıcıya ekle. ref.listen sadece DEĞİŞİM
    // olduğunda çalışır (build her tetiklendiğinde değil), bu yüzden
    // tekrar tekrar çağrılma riski yok; datasource'taki transaction da
    // zaten ikinci bir çağrıyı güvenle görmezden gelir.
    ref.listen(activeSessionProvider(sessionId), (previous, next) {
      final session = next.value;
      if (session != null &&
          session.status == SessionStatus.completed &&
          !session.pointsClaimed) {
        ref.read(claimSessionPointsProvider).call(session);
      }
    });

    // --- ESP32 köprüsü ---
    // Realtime Database'deki canlı komutu (kapak durumu, sayaç) dinleyip
    // Firestore'daki oturuma YANSITIYORUZ. Böylece ActiveSessionPage'in
    // geri kalanı, verinin debug butonundan mı yoksa gerçek ESP32'den mi
    // geldiğini hiç bilmez — ikisi de aynı Firestore alanlarını günceller.
    ref.listen(binCommandProvider(binId), (previous, next) {
      final command = next.value;
      final currentSession = ref.read(activeSessionProvider(sessionId)).value;
      if (command == null || currentSession == null) return;
      // Bu kutunun komutu BAŞKA bir oturuma aitse (ör. önceki kullanıcıdan
      // kalan veri) yok say — sadece kendi oturumumuzu dinliyoruz.
      if (command.sessionId != sessionId) return;

      // Durum ve sayacı TEK bir yazmada gönderiyoruz. Ayrı ayrı
      // gönderilseydi "completed" sayaçtan önce varabilir, puan eski
      // sayaçla hesaplanıp kilitlenebilirdi (kullanıcı puanını kaybederdi).
      final degisti = command.status != currentSession.status ||
          command.depositedCount != currentSession.depositedCount;
      if (!degisti) return;

      ref.read(applyHardwareUpdateProvider).call(
            sessionId: sessionId,
            status: command.status,
            depositedCount: command.depositedCount,
          );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Atık Atma İşlemi')),
      body: sessionAsync.when(
        data: (session) => _SessionBody(session: session),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Hata: $error')),
      ),
    );
  }
}

class _SessionBody extends StatelessWidget {
  const _SessionBody({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(session.wasteType.label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _StatusIndicator(status: session.status),
          const SizedBox(height: 24),
          Text('Algılanan adet: ${session.depositedCount}',
              style: Theme.of(context).textTheme.titleMedium),
          if (session.status == SessionStatus.completed) ...[
            const SizedBox(height: 8),
            Text(
              '+${session.pointsEarned} puan kazandın!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
          // Bu panel SADECE debug modunda görünür (flutter run -d chrome
          // gibi geliştirme çalıştırmalarında). Gerçek APK'da (release)
          // otomatik olarak kaybolur — kullanıcı asla göremez.
          if (kDebugMode) ...[
            const SizedBox(height: 40),
            const Divider(),
            const Text('🔧 Donanım Simülatörü (sadece geliştirme)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _SimulatorPanel(session: session),
          ],
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});
  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, icon) = switch (status) {
      SessionStatus.pending => ('Kapağın açılması bekleniyor...', Icons.hourglass_top),
      SessionStatus.lidOpen => ('Kapak açık — atığını at!', Icons.lock_open),
      SessionStatus.completed => ('Tamamlandı', Icons.check_circle),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(text),
        if (status == SessionStatus.pending) ...[
          const SizedBox(width: 12),
          const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ],
    );
  }
}

/// ESP32 firmware'i yazılana kadar donanımın yapacağı 3 olayı elle
/// tetiklemeyi sağlayan buton grubu. Bastığın her buton, firmware'in
/// ileride Firestore'a yazacağı TAM OLARAK aynı veriyi yazıyor —
/// yani bu ekranın geri kalanı hiç değişmeden gerçek donanıma geçilecek.
class _SimulatorPanel extends ConsumerWidget {
  const _SimulatorPanel({required this.session});
  final RecyclingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton(
          onPressed: session.status == SessionStatus.pending
              ? () => ref
                  .read(updateSessionStatusProvider)
                  .call(session.id, SessionStatus.lidOpen)
              : null,
          child: const Text('Kapağı Aç'),
        ),
        OutlinedButton(
          onPressed: session.status == SessionStatus.lidOpen
              ? () => ref.read(incrementDepositedCountProvider).call(session.id)
              : null,
          child: const Text('+1 Adet Algıla'),
        ),
        OutlinedButton(
          onPressed: session.status == SessionStatus.lidOpen
              ? () => ref
                  .read(updateSessionStatusProvider)
                  .call(session.id, SessionStatus.completed)
              : null,
          child: const Text('Kapağı Kapat / Bitir'),
        ),
      ],
    );
  }
}
