import 'package:material_ui/material_ui.dart';

class RecipeListPage extends StatelessWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Book')),
      body: const Center(child: Text('No recipes yet')),
    );
  }
}
