import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/recipe_type_repository.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/theme_view_model.dart';

/// Who is logged in, a live summary of the cookbook, the status of the
/// downloaded recipe types, the colour theme, and log out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const double _margin = 20;
  static const double _sectionGap = 28;

  /// Wider than this, the page is laid out in two columns.
  static const double _twoColumnWidth = 680;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        // A list, so it scrolls instead of overflowing in landscape.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(_margin, 8, _margin, _margin),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Two columns when there is width to spare (landscape,
                // tablets): who you are and your recipes on the left, the
                // settings on the right. One column on a phone.
                final wide = constraints.maxWidth >= _twoColumnWidth;
                const you = [
                  _Account(),
                  SizedBox(height: _sectionGap),
                  _CookbookSection(),
                ];
                const settings = [
                  _RecipeTypesSection(),
                  SizedBox(height: _sectionGap),
                  _AppearanceSection(),
                  SizedBox(height: _sectionGap),
                  _LogOutButton(),
                ];
                Widget column(List<Widget> children) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                );

                return Align(
                  alignment: Alignment.topCenter,
                  // Capped so it doesn't stretch across a tablet.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 960 : 560),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: column(you)),
                              const SizedBox(width: _margin * 1.5),
                              Expanded(child: column(settings)),
                            ],
                          )
                        : column([
                            ...you,
                            const SizedBox(height: _sectionGap),
                            ...settings,
                          ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Account extends StatelessWidget {
  const _Account();

  @override
  Widget build(BuildContext context) {
    final username =
        context.select((AuthViewModel a) => a.user?.username) ?? '';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        // The one filled accent on this screen: it marks the person.
        CircleAvatar(
          radius: 32,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          child: Text(
            username.isEmpty ? '?' : username[0].toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Signed in on this device',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live numbers: they change as soon as a recipe is added or removed.
class _CookbookSection extends StatelessWidget {
  const _CookbookSection();

  @override
  Widget build(BuildContext context) {
    final stats = context.read<ProfileViewModel>().stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Your cookbook'),
        StreamBuilder<CookbookStats>(
          stream: stats,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _Note('Could not load your recipes.');
            }
            final data = snapshot.data;
            if (data == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            return _CookbookStats(data);
          },
        ),
      ],
    );
  }
}

/// A card with a single plain message, for empty and error states.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

/// One headline number with its label.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookbookStats extends StatelessWidget {
  const _CookbookStats(this.stats);

  final CookbookStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.total == 0) {
      return const _Note(
        'No recipes yet. Add your first one from the Recipes tab.',
      );
    }

    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final most = stats.byType.first.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two equal tiles: the two numbers people look for first.
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: stats.total,
                label: stats.total == 1 ? 'Recipe' : 'Recipes',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(value: stats.favourites, label: 'Favourites'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'By type',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 6),
                for (final type in stats.byType)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${type.count}',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // A thin grey bar, so the most used type is seen at a
                        // glance.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: type.count / most,
                            minHeight: 4,
                            color: muted,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows whether the recipe types came from the server, and lets the user
/// download them again.
class _RecipeTypesSection extends StatelessWidget {
  const _RecipeTypesSection();

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am' : 'pm';
    return '${time.day} ${_months[time.month - 1]}, $hour:$minute $period';
  }

  static String _status(RecipeTypesSource source) => switch (source) {
    RecipeTypesSource.server => 'Up to date from the server',
    RecipeTypesSource.savedCopy => 'Using the last saved copy',
    RecipeTypesSource.bundled => 'Using the list built into the app',
  };

  Future<void> _refresh(BuildContext context) async {
    final viewModel = context.read<ProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final fromServer = await viewModel.refreshTypes();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            fromServer
                ? 'Recipe types updated'
                : 'Could not reach the server. Using the saved copy.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final info = viewModel.typesInfo;
    final theme = Theme.of(context);

    final details = info == null
        ? null
        : [
            '${info.count} types',
            if (info.updatedAt case final at?) 'updated ${_formatTime(at)}',
          ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Recipe types'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info == null ? 'Checking…' : _status(info.source),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (details != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                  onPressed: viewModel.isRefreshing
                      ? null
                      : () => _refresh(context),
                  child: viewModel.isRefreshing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Appearance'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {themeViewModel.mode},
              onSelectionChanged: (selection) =>
                  themeViewModel.setMode(selection.single),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton();

  Future<void> _confirmAndLogOut(BuildContext context) async {
    final auth = context.read<AuthViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need your username and password to log back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
      onPressed: () => _confirmAndLogOut(context),
      icon: const Icon(Icons.logout),
      label: const Text('Log out'),
    );
  }
}
