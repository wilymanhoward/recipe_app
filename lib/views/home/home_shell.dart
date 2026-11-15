import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../viewmodels/profile_view_model.dart';
import '../../viewmodels/recipe_list_view_model.dart';
import '../recipes/recipe_list_page.dart';
import 'profile_page.dart';

/// The logged-in app: Recipes, Favourites and Profile tabs. A bottom bar
/// on phones in portrait, a side rail when there is width to spare
/// (tablets, phones in landscape) so the bar doesn't eat scarce height.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const double railBreakpoint = 600;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<(IconData, IconData, String)> _tabs = [
    (Icons.menu_book_outlined, Icons.menu_book, 'Recipes'),
    (Icons.favorite_border, Icons.favorite, 'Favourites'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  // Built once: IndexedStack keeps every tab alive, so scroll position
  // and filters survive switching tabs.
  late final List<Widget> _pages = [
    _recipeList(favouritesOnly: false),
    _recipeList(favouritesOnly: true),
    ChangeNotifierProvider(
      create: (_) => ProfileViewModel(
        recipeRepository: locator(),
        recipeTypeRepository: locator(),
      ),
      child: const ProfilePage(),
    ),
  ];

  static Widget _recipeList({required bool favouritesOnly}) {
    return ChangeNotifierProvider(
      create: (_) => RecipeListViewModel(
        recipeRepository: locator(),
        recipeTypeRepository: locator(),
        favouritesOnly: favouritesOnly,
      ),
      child: const RecipeListPage(),
    );
  }

  void _select(int index) {
    // A message from one tab shouldn't float over another: on Profile it
    // can cover the buttons at the bottom of the page.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      index: _index,
      children: [
        for (final (index, page) in _pages.indexed)
          // Hidden tabs can show the same recipe card; turning their Heroes
          // off avoids two Heroes with one tag when a recipe is opened.
          HeroMode(enabled: index == _index, child: page),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (isLandscape || constraints.maxWidth >= HomeShell.railBreakpoint) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final (icon, selectedIcon, label) in _tabs)
                        NavigationRailDestination(
                          icon: Icon(icon),
                          selectedIcon: Icon(selectedIcon),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // The rail already sits clear of the notch on the left, so
                // the pages shouldn't add that space again.
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    child: pages,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: pages,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final (icon, selectedIcon, label) in _tabs)
                NavigationDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: label,
                ),
            ],
          ),
        );
      },
    );
  }
}
