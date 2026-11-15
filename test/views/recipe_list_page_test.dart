import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/viewmodels/recipe_list_view_model.dart';
import 'package:recipe_app/views/recipes/recipe_list_page.dart';

import '../helpers/fakes.dart';

void main() {
  final recipes = [
    testRecipe(id: 1, title: 'Pancakes', typeId: 1),
    testRecipe(id: 2, title: 'Mango Sticky Rice', typeId: 4),
  ];

  Future<void> pumpPage(
    WidgetTester tester,
    List<Recipe> recipes, {
    TextScaler? textScaler,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
        home: ChangeNotifierProvider(
          create: (_) => RecipeListViewModel(
            recipeRepository: FakeRecipeRepository(recipes),
            recipeTypeRepository: FakeRecipeTypeRepository(),
          ),
          child: const RecipeListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows every recipe when no filter is selected', (tester) async {
    await pumpPage(tester, recipes);

    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Mango Sticky Rice'), findsOneWidget);
  });

  testWidgets('filters recipes by the selected type', (tester) async {
    await pumpPage(tester, recipes);

    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dessert').last);
    await tester.pumpAndSettle();

    expect(find.text('Pancakes'), findsNothing);
    expect(find.text('Mango Sticky Rice'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no recipes', (tester) async {
    await pumpPage(tester, []);

    expect(find.text('No recipes yet.'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(568, 320), Size(1024, 768)]) {
    testWidgets('lays out without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpPage(tester, recipes);

      // Flutter reports RenderFlex overflows as exceptions during tests.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cards fit with Android-style large text', (tester) async {
    await pumpPage(tester, recipes, textScaler: const _AndroidLikeScaler());

    expect(tester.takeException(), isNull);
  });
}

/// Like Android's largest font setting: small text doubles, large text
/// grows much less.
class _AndroidLikeScaler extends TextScaler {
  const _AndroidLikeScaler();

  @override
  double scale(double fontSize) =>
      fontSize < 20 ? fontSize * 2 : 40 + (fontSize - 20) * 0.5;

  @override
  double get textScaleFactor => 2;
}
