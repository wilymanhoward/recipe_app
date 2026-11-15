import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/recipe_type_repository.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/theme_view_model.dart';

/// Who is logged in, a live summary of the cookbook, a few settings and
/// log out, in that order: a greeting, "Your cookbook", "Settings".
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.onShowRecipes, this.onShowFavourites});

  /// Switch to the Recipes or Favourites tab. When they are null (for
  /// example in a test) the tiles are plain, not tappable.
  final VoidCallback? onShowRecipes;
  final VoidCallback? onShowFavourites;

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
                // tablets): you and your cookbook on the left, the
                // settings on the right. One column on a phone.
                final wide = constraints.maxWidth >= _twoColumnWidth;
                final you = [
                  const _Greeting(),
                  const SizedBox(height: _sectionGap),
                  _CookbookSection(
                    onShowRecipes: onShowRecipes,
                    onShowFavourites: onShowFavourites,
                  ),
                ];
                const settings = [
                  _SettingsSection(),
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

/// The avatar and a hello.
class _Greeting extends StatelessWidget {
  const _Greeting();

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
                username.isEmpty ? 'Hi there!' : 'Hi, $username!',
                maxLines: 2,
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
  const _CookbookSection({this.onShowRecipes, this.onShowFavourites});

  final VoidCallback? onShowRecipes;
  final VoidCallback? onShowFavourites;

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
            if (data.total == 0) return _EmptyCookbook(onAdd: onShowRecipes);
            return _CookbookSummary(
              data,
              onShowRecipes: onShowRecipes,
              onShowFavourites: onShowFavourites,
            );
          },
        ),
      ],
    );
  }
}

/// A card with a single plain message, for error states.
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

/// Shown before the first recipe: says what this section will become and
/// offers the next step.
class _EmptyCookbook extends StatelessWidget {
  const _EmptyCookbook({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your cookbook is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Add your first recipe and it will show up here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAdd,
                child: const Text('Add a recipe'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CookbookSummary extends StatelessWidget {
  const _CookbookSummary(
    this.stats, {
    this.onShowRecipes,
    this.onShowFavourites,
  });

  final CookbookStats stats;
  final VoidCallback? onShowRecipes;
  final VoidCallback? onShowFavourites;

  static const double _gap = 12;

  /// Narrowest a tile may get before the two stack, at normal text size.
  static const double _minTileWidth = 150;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    final recipes = _StatTile(
      value: stats.total,
      label: stats.total == 1 ? 'Recipe' : 'Recipes',
      onTap: onShowRecipes,
    );
    final favourites = _StatTile(
      value: stats.favourites,
      label: 'Favourites',
      onTap: onShowFavourites,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Side by side when each tile has room for its label; stacked
            // on narrow screens or with large text.
            final tileWidth = (constraints.maxWidth - _gap) / 2;
            if (tileWidth >= _minTileWidth * textScale) {
              return Row(
                children: [
                  Expanded(child: recipes),
                  const SizedBox(width: _gap),
                  Expanded(child: favourites),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                recipes,
                const SizedBox(height: _gap),
                favourites,
              ],
            );
          },
        ),
        const SizedBox(height: _gap),
        _ByTypeCard(stats.byType),
      ],
    );
  }
}

/// One headline number with its label. Opens the matching tab when tapped.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.onTap});

  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$value', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              // Hints that the tile is a button.
              if (onTap != null) Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// How many recipes each type has. Shows the top three, and the rest on
/// request, so a long list doesn't push the settings off the screen.
class _ByTypeCard extends StatefulWidget {
  const _ByTypeCard(this.types);

  /// Most used first.
  final List<TypeCount> types;

  @override
  State<_ByTypeCard> createState() => _ByTypeCardState();
}

class _ByTypeCardState extends State<_ByTypeCard> {
  static const int _collapsedCount = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final all = widget.types;
    final shown = _expanded ? all : all.take(_collapsedCount).toList();
    final most = all.first.count;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'By type',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final type in shown) _TypeRow(type: type, most: most),
                ],
              ),
            ),
            if (all.length > _collapsedCount)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show fewer' : 'Show all ${all.length} types',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.most});

  final TypeCount type;
  final int most;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
          // A thin bar, so the most used type is seen at a glance.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: type.count / most,
              minHeight: 6,
              color: theme.colorScheme.secondary,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

/// Appearance and the recipe types, together in one card.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Settings'),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppearanceRow(),
              Divider(height: 1, indent: 16, endIndent: 16),
              _RecipeTypesRow(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<ThemeViewModel>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Appearance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Light, dark, or follow your phone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
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
        ],
      ),
    );
  }
}

/// Shows whether the recipe types came from the server, and lets the user
/// download them again.
class _RecipeTypesRow extends StatelessWidget {
  const _RecipeTypesRow();

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
    final muted = theme.colorScheme.onSurfaceVariant;

    final details = info == null
        ? null
        : [
            '${info.count} types',
            if (info.updatedAt case final at?) 'updated ${_formatTime(at)}',
          ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipe types',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info == null ? 'Checking…' : _status(info.source),
                  style: theme.textTheme.bodyMedium,
                ),
                if (details != null)
                  Text(
                    details,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
            onPressed: viewModel.isRefreshing ? null : () => _refresh(context),
            child: viewModel.isRefreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Refresh'),
          ),
        ],
      ),
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
