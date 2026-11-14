import 'package:material_ui/material_ui.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFFE0703A);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seed,
      brightness: brightness,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
