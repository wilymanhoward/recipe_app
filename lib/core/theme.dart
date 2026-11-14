import 'package:material_ui/material_ui.dart';

/// Warm, homely Material 3 theme: cream paper, terracotta accents,
/// olive highlights and serif headings like a family cookbook.
class AppTheme {
  AppTheme._();

  static const Color _terracotta = Color(0xFFB5562F);

  // Android ships a serif font ("serif" = Noto Serif); iOS falls back to
  // Georgia. Using system fonts keeps the app offline and asset-free.
  static const String _headingFont = 'serif';
  static const List<String> _headingFallback = ['Georgia', 'Times New Roman'];

  static final ColorScheme _lightColors =
      ColorScheme.fromSeed(seedColor: _terracotta).copyWith(
        primary: _terracotta,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFFFDBCB),
        onPrimaryContainer: const Color(0xFF5A1D00),
        secondary: const Color(0xFF66733F),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE5EAC6),
        onSecondaryContainer: const Color(0xFF2C3414),
        surface: const Color(0xFFFBF6EE),
        onSurface: const Color(0xFF3B2A20),
        onSurfaceVariant: const Color(0xFF6B5748),
        surfaceContainerLowest: const Color(0xFFFFFDF9),
        surfaceContainerLow: const Color(0xFFF7EFE4),
        surfaceContainer: const Color(0xFFF3E9DC),
        surfaceContainerHigh: const Color(0xFFEEE2D2),
        surfaceContainerHighest: const Color(0xFFE8DAC7),
        outline: const Color(0xFFA8927F),
        outlineVariant: const Color(0xFFE3D5C3),
      );

  static final ColorScheme _darkColors =
      ColorScheme.fromSeed(
        seedColor: _terracotta,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFFFFB693),
        onPrimary: const Color(0xFF5A1D00),
        primaryContainer: const Color(0xFF7A3418),
        onPrimaryContainer: const Color(0xFFFFDBCB),
        secondary: const Color(0xFFC6D19A),
        onSecondary: const Color(0xFF2C3414),
        secondaryContainer: const Color(0xFF444D27),
        onSecondaryContainer: const Color(0xFFE5EAC6),
        surface: const Color(0xFF1E1712),
        onSurface: const Color(0xFFF1E4D6),
        onSurfaceVariant: const Color(0xFFD5C2B2),
        surfaceContainerLowest: const Color(0xFF18120E),
        surfaceContainerLow: const Color(0xFF261E18),
        surfaceContainer: const Color(0xFF2B221C),
        surfaceContainerHigh: const Color(0xFF362C25),
        surfaceContainerHighest: const Color(0xFF41362E),
        outline: const Color(0xFF9F8B7B),
        outlineVariant: const Color(0xFF4E4239),
      );

  static ThemeData get light => _build(_lightColors);

  static ThemeData get dark => _build(_darkColors);

  static ThemeData _build(ColorScheme colors) {
    final base = ThemeData(useMaterial3: true, colorScheme: colors);
    final text = base.textTheme;

    TextStyle? serif(TextStyle? style, [FontWeight weight = FontWeight.w600]) {
      return style?.copyWith(
        fontFamily: _headingFont,
        fontFamilyFallback: _headingFallback,
        fontWeight: weight,
      );
    }

    final textTheme = text.copyWith(
      displaySmall: serif(text.displaySmall),
      headlineLarge: serif(text.headlineLarge),
      headlineMedium: serif(text.headlineMedium),
      headlineSmall: serif(text.headlineSmall),
      titleLarge: serif(text.titleLarge),
      titleMedium: serif(text.titleMedium),
    );

    const stadium = StadiumBorder();
    final rounded16 = BorderRadius.circular(16);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: rounded16),
        enabledBorder: OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rounded16,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: stadium,
          minimumSize: const Size(64, 52),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: stadium,
          side: BorderSide(color: colors.outline),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        extendedTextStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.surfaceContainerLow),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
    );
  }
}
