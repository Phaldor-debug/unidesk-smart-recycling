import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ünidesk marka renkleri. Rengi değiştirmek istersen SADECE burayı
/// güncellemen yeterli — tüm uygulama buradan besleniyor.
class AppColors {
  AppColors._();

  /// Ana marka rengi — geri dönüşüm kimliği, canlı/enerjik ton.
  static const green = Color(0xFF22C55E);

  /// Puan/ödül vurgu rengi — "kazandığın şey" hep bu renkte görünür.
  static const gold = Color(0xFFFFB800);
}

/// Uygulamanın tek tema kaynağı. Ekranlar renk/font seçmez, hep
/// `Theme.of(context)` üzerinden buradaki değerleri kullanır.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // ColorScheme.fromSeed, Material 3'ün tüm yüzey/kontrast tonlarını
    // otomatik türetir; sonra primary/secondary'i marka renklerimizle
    // sabitliyoruz ki "yeşil + altın" kimliği hep aynı kalsın.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.green,
      secondary: AppColors.gold,
      onSecondary: Colors.black,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: _brandTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.baloo2(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
    );
  }

  /// Başlıklarda enerjik/yuvarlak "Baloo 2", gövde metinde okunaklı
  /// "Inter" kullanıyoruz — ikisi bir arada hem oyunlaştırma hissi
  /// verir hem de uzun metinlerde göz yormaz.
  static TextTheme _brandTextTheme(TextTheme base) {
    final body = GoogleFonts.interTextTheme(base);
    final display = GoogleFonts.baloo2TextTheme(base);

    return body.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
