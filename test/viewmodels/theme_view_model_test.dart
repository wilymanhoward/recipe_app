import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_app/viewmodels/theme_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  test('starts on the system theme', () async {
    final viewModel = ThemeViewModel(settings: FakeSettingsRepository());
    addTearDown(viewModel.dispose);
    await pumpEventQueue();

    expect(viewModel.mode, ThemeMode.system);
  });

  test('a picked theme is saved and loaded again after a restart', () async {
    final settings = FakeSettingsRepository();
    final first = ThemeViewModel(settings: settings);
    addTearDown(first.dispose);

    await first.setMode(ThemeMode.dark);
    expect(first.mode, ThemeMode.dark);

    final afterRestart = ThemeViewModel(settings: settings);
    addTearDown(afterRestart.dispose);
    await pumpEventQueue();

    expect(afterRestart.mode, ThemeMode.dark);
  });

  test('ignores a saved value it does not know', () async {
    final settings = FakeSettingsRepository()..values['theme_mode'] = 'purple';
    final viewModel = ThemeViewModel(settings: settings);
    addTearDown(viewModel.dispose);
    await pumpEventQueue();

    expect(viewModel.mode, ThemeMode.system);
  });
}
