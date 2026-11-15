import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/data/repositories/recipe_type_repository.dart';
import 'package:recipe_app/viewmodels/auth_view_model.dart';
import 'package:recipe_app/viewmodels/profile_view_model.dart';
import 'package:recipe_app/viewmodels/theme_view_model.dart';
import 'package:recipe_app/views/home/profile_page.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeRecipeRepository recipes;
  late FakeRecipeTypeRepository types;
  late FakeSettingsRepository settings;

  setUp(() {
    recipes = FakeRecipeRepository([
      testRecipe(id: 1, isFavourite: true),
      testRecipe(id: 2, title: 'Cake', typeId: 4),
    ]);
    types = FakeRecipeTypeRepository();
    settings = FakeSettingsRepository();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final theme = ThemeViewModel(settings: settings);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthViewModel(
              authRepository: FakeAuthRepository(
                sessionUser: FakeAuthRepository.cook,
              ),
            ),
          ),
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider(
            create: (_) => ProfileViewModel(
              recipeRepository: recipes,
              recipeTypeRepository: types,
            ),
          ),
        ],
        child: Consumer<ThemeViewModel>(
          builder: (_, theme, _) =>
              MaterialApp(themeMode: theme.mode, home: const ProfilePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows who is signed in and the cookbook numbers', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('cook'), findsOneWidget);
    expect(find.text('Your cookbook'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // recipes
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Dessert'), findsOneWidget);
  });

  testWidgets('the numbers update when a recipe is added', (tester) async {
    await pumpPage(tester);

    await recipes.insert(testRecipe(id: 3, title: 'Soup', typeId: 4));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('an empty cookbook points to the Recipes tab', (tester) async {
    recipes = FakeRecipeRepository([]);
    await pumpPage(tester);

    expect(find.textContaining('No recipes yet'), findsOneWidget);
  });

  testWidgets('refresh downloads the types again and says so', (tester) async {
    await pumpPage(tester);
    expect(find.text('Using the list built into the app'), findsOneWidget);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(types.refreshCount, 1);
    expect(find.text('Up to date from the server'), findsOneWidget);
    expect(find.text('Recipe types updated'), findsOneWidget);
  });

  testWidgets('refresh says when the server could not be reached', (
    tester,
  ) async {
    types.refreshSource = RecipeTypesSource.savedCopy;
    await pumpPage(tester);

    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('Using the last saved copy'), findsOneWidget);
    expect(
      find.text('Could not reach the server. Using the saved copy.'),
      findsOneWidget,
    );
  });

  testWidgets('picking Dark changes the theme and saves it', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(settings.values['theme_mode'], 'dark');
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  for (final size in const [Size(320, 568), Size(568, 320), Size(1024, 768)]) {
    testWidgets('lays out without overflow at $size', (tester) async {
      await pumpPage(tester, size: size);

      expect(tester.takeException(), isNull);
    });
  }
}
