import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recipe_app/data/local/image_storage.dart';
import 'package:recipe_app/data/repositories/recipe_repository.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/viewmodels/recipe_detail_view_model.dart';

import '../helpers/fakes.dart';

class MockRecipeRepository extends Mock implements RecipeRepository {}

class MockImageStorage extends Mock implements ImageStorage {}

void main() {
  late MockRecipeRepository repository;
  late MockImageStorage images;

  final withPhoto = Recipe(
    id: 3,
    title: 'Toast',
    typeId: 1,
    imagePath: '/photos/toast.jpg',
    ingredients: const ['Bread'],
    steps: const ['Toast it'],
    createdAt: DateTime(2024),
  );

  setUp(() {
    repository = MockRecipeRepository();
    images = MockImageStorage();
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value([testRecipe(id: 1), withPhoto]));
    when(() => images.delete(any())).thenAnswer((_) async {});
  });

  RecipeDetailViewModel create({int recipeId = 3}) => RecipeDetailViewModel(
    recipeRepository: repository,
    recipeTypeRepository: FakeRecipeTypeRepository(),
    imageStorage: images,
    recipeId: recipeId,
  );

  test('recipe emits the matching recipe', () async {
    expect((await create().recipe.first)?.title, 'Toast');
  });

  test('recipe emits null when the id no longer exists', () async {
    expect(await create(recipeId: 42).recipe.first, isNull);
  });

  test('delete removes the row, then the photo', () async {
    when(() => repository.delete(3)).thenAnswer((_) async {});

    expect(await create().delete(withPhoto), isTrue);

    verifyInOrder([
      () => repository.delete(3),
      () => images.delete('/photos/toast.jpg'),
    ]);
  });

  test('toggleFavourite stores the opposite of the current flag', () async {
    when(
      () => repository.setFavourite(3, isFavourite: any(named: 'isFavourite')),
    ).thenAnswer((_) async {});
    final viewModel = create();

    await viewModel.toggleFavourite(withPhoto);
    await viewModel.toggleFavourite(withPhoto.copyWith(isFavourite: true));

    verifyInOrder([
      () => repository.setFavourite(3, isFavourite: true),
      () => repository.setFavourite(3, isFavourite: false),
    ]);
  });

  test('a failed delete keeps the photo and reports false', () async {
    when(() => repository.delete(3)).thenThrow(Exception('locked'));
    final viewModel = create();

    expect(await viewModel.delete(withPhoto), isFalse);
    expect(viewModel.isDeleting, isFalse);
    verifyNever(() => images.delete(any()));
  });
}
