import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/di/locator.dart';

Future<void> main() async {
  // Needed before using plugins (SQLite, path_provider) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const RecipeApp());
}
