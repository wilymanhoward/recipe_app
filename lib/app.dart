import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'core/theme.dart';
import 'viewmodels/recipe_list_view_model.dart';
import 'views/recipes/recipe_list_page.dart';

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Book',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: ChangeNotifierProvider(
        create: (_) => RecipeListViewModel(
          recipeRepository: locator(),
          recipeTypeRepository: locator(),
        ),
        child: const RecipeListPage(),
      ),
    );
  }
}
