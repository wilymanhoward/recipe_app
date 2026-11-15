import '../../models/recipe.dart';

/// Sample recipes inserted the first time the database is created.
/// Every [Recipe.typeId] must exist in `assets/recipetypes.json`.
List<Recipe> buildSeedRecipes(DateTime now) {
  return [..._originalSeedRecipes(now), ...buildExtraSeedRecipes(now)];
}

/// The first seven sample recipes.
List<Recipe> _originalSeedRecipes(DateTime now) {
  // Timestamps are staggered so the newest-first order is stable.
  return [
    Recipe(
      title: 'Nasi Lemak',
      imagePath: 'assets/images/recipes/nasi_lemak.jpg',
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
      imagePath: 'assets/images/recipes/fluffy_pancakes.jpg',
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
      imagePath: 'assets/images/recipes/chicken_fried_rice.jpg',
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
      imagePath: 'assets/images/recipes/garlic_butter_salmon.jpg',
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
      imagePath: 'assets/images/recipes/mango_sticky_rice.jpg',
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
      imagePath: 'assets/images/recipes/pisang_goreng.jpg',
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
      imagePath: 'assets/images/recipes/teh_tarik.jpg',
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

/// Ten more sample recipes, added in database version 4. Kept apart from
/// [_originalSeedRecipes] so an upgrade can insert just these for people who
/// already have the first seven.
List<Recipe> buildExtraSeedRecipes(DateTime now) {
  // A day older than the first seven, and staggered, so the order is stable
  // and people's own newer recipes stay on top.
  DateTime at(int index) => now.subtract(Duration(days: 1, minutes: index));

  return [
    Recipe(
      title: 'Roti Canai',
      imagePath: 'assets/images/recipes/roti_canai.jpg',
      typeId: 1,
      ingredients: const [
        '3 cups plain flour',
        '1 tsp salt',
        '1 tbsp sugar',
        '1 egg',
        '1 cup water',
        '4 tbsp melted ghee or butter, plus more for cooking',
        'Chicken or dhal curry, to serve',
      ],
      steps: const [
        'Mix the flour, salt and sugar. Add the egg, 2 tbsp ghee and the water, then knead into a soft dough for 10 minutes.',
        'Divide into 6 balls, coat each with ghee and rest for at least 1 hour.',
        'Stretch each ball very thin on an oiled surface, then fold or coil it.',
        'Cook on a hot, greased pan for 2 minutes per side until golden.',
        'Crush the roti between your hands to fluff it up and serve with curry.',
      ],
      createdAt: at(0),
    ),
    Recipe(
      title: 'Avocado Toast with Egg',
      imagePath: 'assets/images/recipes/avocado_toast.jpg',
      typeId: 1,
      ingredients: const [
        '2 slices sourdough bread',
        '1 ripe avocado',
        '2 eggs',
        '1 tsp lemon juice',
        'Chilli flakes',
        'Salt and pepper',
      ],
      steps: const [
        'Toast the bread until crisp.',
        'Mash the avocado with the lemon juice, salt and pepper.',
        'Poach or fry the eggs for about 3 minutes, so the yolks stay soft.',
        'Spread the avocado on the toast, top with the eggs and sprinkle with chilli flakes.',
      ],
      createdAt: at(1),
    ),
    Recipe(
      title: 'Mee Goreng Mamak',
      imagePath: 'assets/images/recipes/mee_goreng_mamak.jpg',
      typeId: 2,
      ingredients: const [
        '300 g yellow noodles',
        '2 tbsp cooking oil',
        '3 cloves garlic, minced',
        '100 g prawns, peeled',
        '1 egg',
        '1 potato, boiled and cubed',
        '1 tomato, cut into wedges',
        '2 tbsp chilli sauce',
        '1 tbsp soy sauce',
        '2 handfuls choy sum',
        '1 lime, to serve',
      ],
      steps: const [
        'Heat the oil and fry the garlic until fragrant.',
        'Add the prawns and cook until pink, then push them aside and scramble the egg.',
        'Add the noodles, chilli sauce and soy sauce, and toss over high heat.',
        'Stir in the potato, tomato and choy sum and cook for 2 more minutes.',
        'Serve hot with a squeeze of lime.',
      ],
      createdAt: at(2),
    ),
    Recipe(
      title: 'Tomato Basil Pasta',
      imagePath: 'assets/images/recipes/tomato_basil_pasta.jpg',
      typeId: 2,
      ingredients: const [
        '250 g spaghetti',
        '2 tbsp olive oil',
        '3 cloves garlic, sliced',
        '400 g canned chopped tomatoes',
        'A handful of fresh basil',
        'Grated parmesan, to serve',
        'Salt',
      ],
      steps: const [
        'Boil the spaghetti in well-salted water until just tender, then drain, keeping a cup of the water.',
        'Warm the oil and cook the garlic for 30 seconds without browning it.',
        'Add the tomatoes and a pinch of salt and simmer for 10 minutes.',
        'Toss the pasta in the sauce, loosening it with a splash of the pasta water.',
        'Tear in the basil and serve with parmesan.',
      ],
      createdAt: at(3),
    ),
    Recipe(
      title: 'Chicken Satay',
      imagePath: 'assets/images/recipes/chicken_satay.jpg',
      typeId: 3,
      ingredients: const [
        '500 g chicken thigh, cut into strips',
        '1 stalk lemongrass, finely chopped',
        '2 tsp ground turmeric',
        '2 tsp ground coriander',
        '1 tbsp sugar',
        '2 tbsp oil',
        '1/2 cup peanut butter',
        '1/2 cup coconut milk',
        'Bamboo skewers, soaked in water',
      ],
      steps: const [
        'Mix the lemongrass, turmeric, coriander, sugar and oil, then coat the chicken and marinate for at least 2 hours.',
        'Thread the chicken onto the skewers.',
        'Grill for about 4 minutes per side, until charred at the edges and cooked through.',
        'Warm the peanut butter with the coconut milk and a pinch of salt for the dipping sauce.',
        'Serve the skewers with the sauce.',
      ],
      createdAt: at(4),
    ),
    Recipe(
      title: 'Beef Rendang',
      imagePath: 'assets/images/recipes/beef_rendang.jpg',
      typeId: 3,
      ingredients: const [
        '1 kg beef chuck, cubed',
        '400 ml coconut milk',
        '4 tbsp toasted grated coconut',
        '2 stalks lemongrass, bruised',
        '4 kaffir lime leaves',
        '2 tbsp tamarind paste',
        '10 dried chillies, soaked',
        '5 shallots',
        '4 cloves garlic',
        '2 cm ginger and 2 cm galangal',
        'Salt and sugar',
      ],
      steps: const [
        'Blend the chillies, shallots, garlic, ginger and galangal into a paste.',
        'Fry the paste in a little oil until fragrant and the oil separates.',
        'Add the beef and coat it, then pour in the coconut milk and add the lemongrass and lime leaves.',
        'Simmer gently for about 2 hours, stirring now and then, until the sauce thickens.',
        'Stir in the toasted coconut and tamarind, season, and cook until the beef is dark and almost dry.',
      ],
      createdAt: at(5),
    ),
    Recipe(
      title: 'Curry Puffs',
      imagePath: 'assets/images/recipes/curry_puffs.jpg',
      typeId: 5,
      ingredients: const [
        '2 cups plain flour',
        '80 g cold butter, cubed',
        '1/2 cup cold water',
        '1 potato, diced small',
        '150 g minced chicken',
        '1 onion, diced',
        '2 tbsp curry powder',
        'Oil, for frying',
      ],
      steps: const [
        'Rub the butter into the flour, add the water and bring it together into a dough. Rest for 30 minutes.',
        'Fry the onion, then the chicken and curry powder. Add the potato and a splash of water and cook until soft. Let it cool.',
        'Roll the dough thin and cut into circles.',
        'Put a spoonful of filling on each circle, fold over and crimp the edge.',
        'Deep-fry in medium-hot oil until golden and crisp.',
      ],
      createdAt: at(6),
    ),
    Recipe(
      title: 'Cendol',
      imagePath: 'assets/images/recipes/cendol.jpg',
      typeId: 4,
      ingredients: const [
        '1 cup cendol jelly',
        '1 cup shaved ice',
        '1/2 cup coconut milk',
        '4 tbsp gula melaka syrup',
        '2 tbsp sweet corn or red beans',
      ],
      steps: const [
        'Put the cendol jelly and the sweet corn or red beans in a bowl.',
        'Pile the shaved ice on top.',
        'Pour over the coconut milk, then the gula melaka syrup.',
        'Serve right away, before the ice melts.',
      ],
      createdAt: at(7),
    ),
    Recipe(
      title: 'Mango Lassi',
      imagePath: 'assets/images/recipes/mango_lassi.jpg',
      typeId: 6,
      ingredients: const [
        '2 ripe mangoes, peeled and chopped',
        '1 cup plain yoghurt',
        '1/2 cup cold milk',
        '1 tbsp honey',
        '4 ice cubes',
        'A pinch of cardamom',
      ],
      steps: const [
        'Put the mango, yoghurt, milk, honey and ice in a blender.',
        'Blend until completely smooth.',
        'Taste and add more honey if the mangoes are not sweet enough.',
        'Pour into tall glasses and dust with cardamom.',
      ],
      createdAt: at(8),
    ),
    Recipe(
      title: 'Iced Lemon Tea',
      imagePath: 'assets/images/recipes/iced_lemon_tea.jpg',
      typeId: 6,
      ingredients: const [
        '3 black tea bags',
        '3 cups boiling water',
        '1/4 cup sugar',
        '1/4 cup lemon juice',
        'Ice',
        'Lemon slices, to serve',
      ],
      steps: const [
        'Steep the tea bags in the boiling water for 4 minutes, then remove them.',
        'Stir in the sugar until it dissolves and let the tea cool.',
        'Add the lemon juice.',
        'Pour over a glass of ice and add a slice of lemon.',
      ],
      createdAt: at(9),
    ),
  ];
}
