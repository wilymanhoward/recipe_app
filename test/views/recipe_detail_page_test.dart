import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/viewmodels/recipe_detail_view_model.dart';
import 'package:recipe_app/views/recipes/recipe_detail_page.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeRecipeRepository repository;
  final recipe = Recipe(
    id: 1,
    title: 'Pancakes',
    typeId: 1,
    ingredients: const ['Flour', 'Milk'],
    steps: const ['Mix the batter', 'Cook until golden'],
    createdAt: DateTime(2024),
  );

  setUp(() => repository = FakeRecipeRepository([recipe]));

  Widget detailPage({int recipeId = 1}) {
    return ChangeNotifierProvider(
      create: (_) => RecipeDetailViewModel(
        recipeRepository: repository,
        recipeTypeRepository: FakeRecipeTypeRepository(),
        imageStorage: FakeImageStorage(),
        recipeId: recipeId,
      ),
      child: const RecipeDetailPage(),
    );
  }

  /// Opens the detail page from a home screen, like the real app does,
  /// and returns the value the page pops with.
  Future<List<String?>> openFromHome(WidgetTester tester) async {
    final results = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await Navigator.of(
                context,
              ).push(MaterialPageRoute<String>(builder: (_) => detailPage()));
              results.add(result);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('shows the type, title, ingredients and steps', (tester) async {
    await tester.pumpWidget(MaterialApp(home: detailPage()));
    await tester.pumpAndSettle();

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Pancakes'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Cook until golden'), findsOneWidget);
    expect(find.text('Edit recipe'), findsOneWidget);
  });

  testWidgets('delete asks first, then removes and closes', (tester) async {
    final results = await openFromHome(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Pancakes"?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.recipes, isEmpty);
    expect(find.byType(RecipeDetailPage), findsNothing);
    expect(results, ['Pancakes']);
  });

  testWidgets('cancelling delete keeps the recipe', (tester) async {
    await openFromHome(tester);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.recipes, hasLength(1));
    expect(find.byType(RecipeDetailPage), findsOneWidget);
  });

  testWidgets('a missing recipe shows a message', (tester) async {
    await tester.pumpWidget(MaterialApp(home: detailPage(recipeId: 99)));
    await tester.pumpAndSettle();

    expect(find.text('This recipe no longer exists.'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(568, 320), Size(1024, 768)]) {
    testWidgets('lays out without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: detailPage()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
