import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
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
      home: const RecipeListPage(),
    );
  }
}
