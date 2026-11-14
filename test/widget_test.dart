import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_app/app.dart';

void main() {
  testWidgets('App starts on the recipe list page', (tester) async {
    await tester.pumpWidget(const RecipeApp());

    expect(find.text('Recipe Book'), findsOneWidget);
  });
}
