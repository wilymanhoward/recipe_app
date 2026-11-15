import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/viewmodels/recipe_form_view_model.dart';
import 'package:recipe_app/views/recipes/recipe_form_page.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeRecipeRepository repository;

  setUp(() => repository = FakeRecipeRepository([]));

  Future<void> pumpForm(WidgetTester tester, {Recipe? initial}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => RecipeFormViewModel(
            recipeRepository: repository,
            recipeTypeRepository: FakeRecipeTypeRepository(),
            imageStorage: FakeImageStorage(),
            initial: initial,
          ),
          child: const RecipeFormPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addItem(WidgetTester tester, String hint, String text) async {
    await tester.enterText(find.widgetWithText(TextField, hint), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save recipe'));
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows validation errors for an empty form', (tester) async {
    await pumpForm(tester);

    await tapSave(tester);

    expect(find.text('Enter a recipe name'), findsOneWidget);
    expect(find.text('Choose a recipe type'), findsOneWidget);
    expect(find.text('Add at least one ingredient'), findsOneWidget);
    expect(find.text('Add at least one step'), findsOneWidget);
    expect(repository.recipes, isEmpty);
  });

  testWidgets('saves a completed recipe', (tester) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Recipe name'),
      'Omelette',
    );
    final typeDropdown = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(typeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(typeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Breakfast').last);
    await tester.pumpAndSettle();
    await addItem(tester, 'e.g. 2 cups flour', 'Eggs');
    await addItem(tester, 'Describe the next step', 'Whisk and fry');

    expect(find.text('Eggs'), findsOneWidget);
    await tapSave(tester);

    expect(repository.recipes.single.title, 'Omelette');
    expect(repository.recipes.single.steps, ['Whisk and fry']);
  });

  testWidgets('editing a recipe whose type was removed asks for a new type', (
    tester,
  ) async {
    // e.g. recipetypes.json was replaced and type 99 no longer exists.
    await pumpForm(tester, initial: testRecipe(typeId: 99));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a recipe type'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(568, 320)]) {
    testWidgets('lays out without overflow at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpForm(tester);

      expect(tester.takeException(), isNull);
    });
  }
}
