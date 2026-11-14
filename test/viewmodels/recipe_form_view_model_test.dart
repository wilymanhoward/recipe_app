import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipe_app/data/local/image_storage.dart';
import 'package:recipe_app/data/repositories/recipe_repository.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/viewmodels/recipe_form_view_model.dart';

import '../helpers/fakes.dart';

class MockRecipeRepository extends Mock implements RecipeRepository {}

class MockImageStorage extends Mock implements ImageStorage {}

void main() {
  late MockRecipeRepository repository;
  late MockImageStorage images;

  setUpAll(() => registerFallbackValue(testRecipe()));

  setUp(() {
    repository = MockRecipeRepository();
    images = MockImageStorage();
    when(() => images.delete(any())).thenAnswer((_) async {});
    when(() => repository.update(any())).thenAnswer((_) async {});
    when(() => repository.insert(any())).thenAnswer(
      (call) async =>
          (call.positionalArguments.first as Recipe).copyWith(id: 99),
    );
  });

  RecipeFormViewModel create({Recipe? initial}) => RecipeFormViewModel(
    recipeRepository: repository,
    recipeTypeRepository: FakeRecipeTypeRepository(),
    imageStorage: images,
    initial: initial,
  );

  void fillIn(RecipeFormViewModel viewModel) {
    viewModel
      ..setTitle('  Omelette  ')
      ..setType(1)
      ..addItem(RecipeSection.ingredients, 'Eggs')
      ..addItem(RecipeSection.steps, 'Whisk and fry');
  }

  group('create', () {
    test('save inserts a trimmed recipe and returns it with an id', () async {
      final viewModel = create();
      fillIn(viewModel);

      final saved = await viewModel.save();

      expect(saved?.id, 99);
      final inserted =
          verify(() => repository.insert(captureAny())).captured.single
              as Recipe;
      expect(inserted.title, 'Omelette');
      expect(inserted.ingredients, ['Eggs']);
      expect(viewModel.hasUnsavedChanges, isFalse);
    });

    test('save refuses an incomplete recipe', () async {
      final viewModel = create()..setTitle('Omelette');

      expect(await viewModel.save(), isNull);
      expect(viewModel.errorMessage, isNotNull);
      verifyNever(() => repository.insert(any()));
    });

    test('save reports a database failure instead of throwing', () async {
      when(() => repository.insert(any())).thenThrow(Exception('disk full'));
      final viewModel = create();
      fillIn(viewModel);

      expect(await viewModel.save(), isNull);
      expect(viewModel.errorMessage, contains('Could not save'));
      expect(viewModel.isSaving, isFalse);
    });
  });

  group('edit', () {
    final original = Recipe(
      id: 5,
      title: 'Toast',
      typeId: 1,
      imagePath: '/photos/old.jpg',
      ingredients: const ['Bread'],
      steps: const ['Toast it'],
      createdAt: DateTime(2024),
    );

    test('save updates the recipe and keeps its id and date', () async {
      final viewModel = create(initial: original)..setTitle('Butter toast');

      await viewModel.save();

      final updated =
          verify(() => repository.update(captureAny())).captured.single
              as Recipe;
      expect(updated.id, 5);
      expect(updated.createdAt, DateTime(2024));
      expect(updated.title, 'Butter toast');
    });

    test('replacing the photo deletes the old one only after saving', () async {
      when(() => images.pick(ImageSource.gallery))
          .thenAnswer((_) async => '/photos/new.jpg');
      final viewModel = create(initial: original);

      await viewModel.pickImage(ImageSource.gallery);
      verifyNever(() => images.delete('/photos/old.jpg'));

      await viewModel.save();
      verify(() => images.delete('/photos/old.jpg')).called(1);
      verifyNever(() => images.delete('/photos/new.jpg'));
    });

    test('leaving without saving keeps the original photo', () async {
      when(() => images.pick(ImageSource.gallery))
          .thenAnswer((_) async => '/photos/new.jpg');
      final viewModel = create(initial: original);

      await viewModel.pickImage(ImageSource.gallery);
      viewModel.dispose();

      verify(() => images.delete('/photos/new.jpg')).called(1);
      verifyNever(() => images.delete('/photos/old.jpg'));
    });
  });

  test('picking a second photo deletes the first unsaved one', () async {
    final paths = ['/photos/a.jpg', '/photos/b.jpg'];
    when(() => images.pick(ImageSource.camera))
        .thenAnswer((_) async => paths.removeAt(0));
    final viewModel = create();

    await viewModel.pickImage(ImageSource.camera);
    await viewModel.pickImage(ImageSource.camera);

    expect(viewModel.imagePath, '/photos/b.jpg');
    verify(() => images.delete('/photos/a.jpg')).called(1);
  });

  test('moveItem moves an item to its new position', () {
    final viewModel = create()
      ..addItem(RecipeSection.steps, 'A')
      ..addItem(RecipeSection.steps, 'B')
      ..addItem(RecipeSection.steps, 'C');

    viewModel.moveItem(RecipeSection.steps, 0, 2);

    expect(viewModel.items(RecipeSection.steps), ['B', 'C', 'A']);
  });

  test('blank items are ignored', () {
    final viewModel = create()..addItem(RecipeSection.ingredients, '   ');

    expect(viewModel.items(RecipeSection.ingredients), isEmpty);
  });
}
