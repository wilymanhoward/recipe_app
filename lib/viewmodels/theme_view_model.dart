import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/repositories/settings_repository.dart';

/// The colour theme the user picked (system, light or dark). Saved, so it
/// is still there after the app restarts.
class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel({required this._settings}) {
    unawaited(_load());
  }

  static const String _key = 'theme_mode';

  final SettingsRepository _settings;

  ThemeMode _mode = ThemeMode.system;
  bool _isDisposed = false;

  ThemeMode get mode => _mode;

  Future<void> _load() async {
    final String? saved;
    try {
      saved = await _settings.read(_key);
    } catch (error) {
      // A theme that can't be read is not worth a crash: stay on "system".
      debugPrint('Could not read the theme setting: $error');
      return;
    }
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode == null || _isDisposed || mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _settings.write(_key, mode.name);
    } catch (error) {
      // Still applied for this session; it just won't be remembered.
      debugPrint('Could not save the theme setting: $error');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
