import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final username = auth.user?.username ?? '';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        // A list, so it scrolls instead of overflowing in landscape.
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Text(
                  username.isEmpty ? '?' : username[0].toUpperCase(),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              username,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Logged in on this device',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: OutlinedButton.icon(
                onPressed: auth.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
