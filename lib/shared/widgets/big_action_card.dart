import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan büyük, renkli, basılınca hafifçe küçülen
/// interaktif kart. İlk olarak SelectWastePage için yazıldı, artık ortak —
/// Ödüller, ana sayfa gibi başka ekranlar da aynı görsel dili kullanıyor.
class BigActionCard extends StatefulWidget {
  const BigActionCard({
    super.key,
    required this.color,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconAsset,
    this.onTap,
    this.enabled = true,
    this.trailing,
  });

  final Color color;
  final String title;
  final String? subtitle;

  /// İkisinden biri verilir: Material ikon (ör. Icons.redeem) ya da
  /// assets/icons altındaki özel çizilmiş bir görsel.
  final IconData? icon;
  final String? iconAsset;

  final VoidCallback? onTap;

  /// false ise kart soluk görünür ve dokunulamaz (ör. yetersiz puan).
  final bool enabled;

  /// Varsayılan sağ ok yerine farklı bir widget göstermek istersen.
  final Widget? trailing;

  @override
  State<BigActionCard> createState() => _BigActionCardState();
}

class _BigActionCardState extends State<BigActionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Kapalıyken renk soluklaşır — "bu an tıklanamaz" hissi rengi
    // değiştirmeden de anlaşılsın diye opaklığı düşürüyoruz.
    final effectiveColor = widget.enabled ? widget.color : widget.color.withValues(alpha: 0.35);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            children: [
              if (widget.icon != null || widget.iconAsset != null)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: widget.iconAsset != null
                      ? Image.asset(widget.iconAsset!, color: Colors.white)
                      : Icon(widget.icon, color: Colors.white),
                ),
              if (widget.icon != null || widget.iconAsset != null) const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ],
                ),
              ),
              widget.trailing ??
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: widget.enabled ? 1 : 0.6),
                    size: 28,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
