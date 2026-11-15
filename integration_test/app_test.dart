import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_app/app.dart';
import 'package:recipe_app/core/di/locator.dart';

/// Runs the real app on a device or emulator, with the real database,
/// secure storage and network:
///   flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Unique per run, so the test can be repeated on the same device.
  final runId = DateTime.now().millisecondsSinceEpoch % 1000000;
  final username = 'tester$runId';
  final title = 'Kaya Toast $runId';
  final editedTitle = 'Kaya Butter Toast $runId';

  Future<void> tapText(WidgetTester tester, String text) async {
    // Close the on-screen keyboard first: while it slides away the layout
    // moves, and a tap can land where the button was a moment ago.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Log out asks first; confirm in the dialog.
  Future<void> logOut(WidgetTester tester) async {
    await tapText(tester, 'Log out');
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
  }

  /// Saving goes through the real database, which is I/O rather than an
  /// animation, so pumpAndSettle can return before the result shows up.
  /// Keep pumping until [finder] matches, for up to 5 seconds.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  Future<void> fillField(
    WidgetTester tester,
    String label,
    String text, {
    bool isHint = false,
  }) async {
    final finder = isHint
        ? find.widgetWithText(TextField, label)
        : find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  testWidgets('sign up, then create, favourite, edit and delete a recipe', (
    tester,
  ) async {
    await setupLocator();
    await tester.pumpWidget(const RecipeApp());
    await tester.pumpAndSettle();

    // A session from an earlier run skips the login page: log out first.
    if (find.text('Profile').evaluate().isNotEmpty) {
      await tapText(tester, 'Profile');
      await logOut(tester);
    }

    // Sign up.
    await tapText(tester, 'New here? Create an account');
    await fillField(tester, 'Username', username);
    await fillField(tester, 'Password', 'secret123');
    await fillField(tester, 'Confirm password', 'secret123');
    await tapText(tester, 'Create account');
    expect(find.text('Recipe Book'), findsOneWidget);

    // Refreshing the recipe types must reach the Recipes tab, which stays
    // open in the background. (Either answer is fine: the server's, or the
    // saved copy if the device is offline.)
    await tapText(tester, 'Profile');
    await tapText(tester, 'Refresh');
    await waitFor(
      tester,
      find.textContaining(RegExp('Recipe types updated|Could not reach')),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Recipes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All types'));
    await tester.pumpAndSettle();
    expect(find.text('Breakfast'), findsWidgets);
    // Close the menu again by choosing "All types".
    await tester.tap(find.text('All types').last);
    await tester.pumpAndSettle();

    // Create a recipe.
    await tapText(tester, 'Add recipe');
    await fillField(tester, 'Recipe name', title);
    final typeField = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(typeField);
    await tester.tap(typeField);
    await tester.pumpAndSettle();
    await tapText(tester, 'Breakfast');
    await fillField(
      tester,
      'e.g. 2 cups flour',
      '2 slices bread',
      isHint: true,
    );
    await tester.tap(find.byTooltip('Add').first);
    await tester.pumpAndSettle();
    await fillField(
      tester,
      'Describe the next step',
      'Toast and spread kaya',
      isHint: true,
    );
    await tester.tap(find.byTooltip('Add').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'Save recipe');
    await waitFor(tester, find.text('"$title" saved'));

    // Open it and mark it as a favourite.
    await tapText(tester, title);
    expect(find.text('Toast and spread kaya'), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tapText(tester, 'Favourites');
    expect(find.text(title), findsOneWidget);

    // Edit it from the Favourites tab.
    await tapText(tester, title);
    await tapText(tester, 'Edit recipe');
    await fillField(tester, 'Recipe name', editedTitle);
    await tapText(tester, 'Save changes');
    await waitFor(tester, find.text('Changes saved'));
    expect(find.text(editedTitle), findsWidgets);
    // Editing keeps the heart.
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);

    // Delete it.
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('"$editedTitle" deleted'));
    expect(find.text(editedTitle), findsNothing);

    // Log out again so the device is left on the login page.
    await tapText(tester, 'Profile');
    expect(find.text(username), findsOneWidget);
    await logOut(tester);
    expect(find.text('Log in'), findsOneWidget);
  });
}
