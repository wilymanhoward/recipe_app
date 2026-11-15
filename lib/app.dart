import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'core/theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_shell.dart';

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp so every page can read who is logged in.
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(authRepository: locator()),
      child: MaterialApp(
        title: 'Recipe Book',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows the login page or the app depending on the session, so logging
/// out can never leave a recipe screen open behind it.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (auth.status) {
        AuthStatus.checking => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthStatus.signedOut => const LoginPage(),
        // Keyed by user, so the next person to log in starts with fresh tabs.
        AuthStatus.signedIn => HomeShell(key: ValueKey(auth.user?.id)),
      },
    );
  }
}
