import '../../models/recipe.dart';

/// Sample recipes inserted the first time the database is created.
/// Every [Recipe.typeId] must exist in `assets/recipetypes.json`.
List<Recipe> buildSeedRecipes(DateTime now) {
  // Timestamps are staggered so the newest-first order is stable.
  return [
    Recipe(
      title: 'Nasi Lemak',
      typeId: 1,
      ingredients: const [
        '2 cups jasmine rice',
        '1 cup coconut milk',
        '2 pandan leaves, knotted',
        '4 tbsp sambal',
        '2 hard-boiled eggs',
        'Fried anchovies and roasted peanuts',
        'Sliced cucumber',
      ],
      steps: const [
        'Rinse the rice until the water runs clear.',
        'Cook the rice with coconut milk, 1 cup water, pandan and a pinch of salt.',
        'Halve the eggs and slice the cucumber.',
        'Serve the rice with sambal, egg, anchovies, peanuts and cucumber.',
      ],
      createdAt: now.subtract(const Duration(minutes: 0)),
    ),
    Recipe(
      title: 'Fluffy Pancakes',
      typeId: 1,
      ingredients: const [
        '1 1/2 cups plain flour',
        '2 tbsp sugar',
        '2 tsp baking powder',
        '1 1/4 cups milk',
        '1 egg',
        '3 tbsp melted butter',
      ],
      steps: const [
        'Whisk the flour, sugar, baking powder and a pinch of salt.',
        'Whisk the milk, egg and butter, then fold into the dry mix.',
        'Rest the batter for 5 minutes.',
        'Cook 1/4 cup portions on a buttered pan until bubbles form, then flip.',
      ],
      createdAt: now.subtract(const Duration(minutes: 1)),
    ),
    Recipe(
      title: 'Chicken Fried Rice',
      typeId: 2,
      ingredients: const [
        '3 cups cooked day-old rice',
        '200 g chicken breast, diced',
        '2 eggs',
        '1 cup mixed vegetables',
        '3 cloves garlic, minced',
        '2 tbsp soy sauce',
        '1 tbsp oyster sauce',
      ],
      steps: const [
        'Fry the garlic in oil until fragrant, then cook the chicken through.',
        'Push to one side and scramble the eggs.',
        'Add the vegetables and rice, stir-frying on high heat.',
        'Season with soy and oyster sauce and toss well.',
      ],
      createdAt: now.subtract(const Duration(minutes: 2)),
    ),
    Recipe(
      title: 'Garlic Butter Salmon',
      typeId: 3,
      ingredients: const [
        '2 salmon fillets',
        '3 tbsp butter',
        '4 cloves garlic, minced',
        '1 lemon',
        'Salt and black pepper',
        'Chopped parsley',
      ],
      steps: const [
        'Season the salmon with salt and pepper.',
        'Sear skin-side down for 4 minutes, flip and cook 3 more.',
        'Lower the heat, add butter and garlic and baste the fish.',
        'Finish with lemon juice and parsley.',
      ],
      createdAt: now.subtract(const Duration(minutes: 3)),
    ),
    Recipe(
      title: 'Mango Sticky Rice',
      typeId: 4,
      ingredients: const [
        '1 cup glutinous rice, soaked overnight',
        '1 cup coconut milk',
        '1/3 cup sugar',
        '1/2 tsp salt',
        '2 ripe mangoes',
      ],
      steps: const [
        'Steam the soaked rice for 25 minutes.',
        'Warm the coconut milk with sugar and salt until dissolved.',
        'Stir 3/4 of the coconut milk into the hot rice and rest 15 minutes.',
        'Serve with sliced mango and the remaining coconut milk.',
      ],
      createdAt: now.subtract(const Duration(minutes: 4)),
    ),
    Recipe(
      title: 'Pisang Goreng',
      typeId: 5,
      ingredients: const [
        '6 ripe bananas',
        '1 cup rice flour',
        '2 tbsp plain flour',
        '1/2 tsp baking powder',
        '3/4 cup cold water',
        'Oil for frying',
      ],
      steps: const [
        'Mix the flours, baking powder, a pinch of salt and the water into a batter.',
        'Peel the bananas and halve them lengthwise.',
        'Dip in the batter and deep-fry until golden.',
        'Drain on paper towels and serve warm.',
      ],
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
    Recipe(
      title: 'Teh Tarik',
      typeId: 6,
      ingredients: const [
        '2 black tea bags',
        '1 1/2 cups boiling water',
        '3 tbsp sweetened condensed milk',
        '2 tbsp evaporated milk',
      ],
      steps: const [
        'Steep the tea in boiling water for 5 minutes.',
        'Stir in the condensed and evaporated milk.',
        'Pour back and forth between two jugs from a height until frothy.',
      ],
      createdAt: now.subtract(const Duration(minutes: 6)),
    ),
  ];
}
