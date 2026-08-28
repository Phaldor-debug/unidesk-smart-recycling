import 'package:flutter/material.dart';

/// Boş listelerde gösterilen ortak görünüm.
///
/// Tek bir bileşende topluyoruz çünkü her ekran kendi boş durumunu
/// yazdığında hepsi biraz farklı görünüyordu. Boş ekran, uygulamanın
/// "bozuk mu, yoksa gerçekten boş mu" sorusuna cevap verdiği yerdir —
/// tutarlı olması güven veriyor.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accent,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;

  /// İkonun rengi. Verilmezse temanın ana rengi kullanılır.
  final Color? accent;

  /// İsteğe bağlı yönlendirme butonu — kullanıcı boş ekranda
  /// ne yapacağını bilsin diye.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final renk = accent ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: renk),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
