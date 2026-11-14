import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

/// Registers app-wide services. Called once from [main] before [runApp].
Future<void> setupLocator() async {
  // Repositories and data sources are registered here from Phase 1 onwards.
}
