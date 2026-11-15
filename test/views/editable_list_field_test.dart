import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recipe_app/views/recipes/editable_list_field.dart';

void main() {
  /// Hosts the field with a real list, the way the form's ViewModel does.
  Future<List<String>> pumpField(
    WidgetTester tester, {
    List<String> initial = const ['Flour', 'Milk', 'Eggs'],
  }) async {
    final items = [...initial];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => EditableListField(
              label: 'Ingredients',
              hintText: 'e.g. 2 cups flour',
              items: List.of(items),
              numbered: false,
              onAdd: (value) => setState(() => items.add(value.trim())),
              onEdit: (index, value) => setState(() => items[index] = value),
              onRemove: (index) => setState(() => items.removeAt(index)),
              onReorder: (oldIndex, newIndex) => setState(
                () => items.insert(newIndex, items.removeAt(oldIndex)),
              ),
            ),
          ),
        ),
      ),
    );
    return items;
  }

  testWidgets('adds an item with the button and ignores blanks', (
    tester,
  ) async {
    final items = await pumpField(tester, initial: []);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Add'));
    await tester.pump();
    expect(items, isEmpty);

    await tester.enterText(find.byType(TextField), 'Sugar');
    await tester.tap(find.byTooltip('Add'));
    await tester.pump();
    expect(items, ['Sugar']);
    expect(find.text('Sugar'), findsOneWidget);
  });

  testWidgets('tapping an item edits it; Cancel keeps it', (tester) async {
    final items = await pumpField(tester);

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    expect(find.text('Edit ingredient'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Oat milk');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(items[1], 'Milk');

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Oat milk');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(items[1], 'Oat milk');
  });

  testWidgets('the bin removes the item', (tester) async {
    final items = await pumpField(tester);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pump();

    expect(items, ['Milk', 'Eggs']);
  });

  testWidgets('dragging the handle reorders items', (tester) async {
    final items = await pumpField(tester);

    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    // Move below the last row, in small steps like a real finger.
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(items, ['Milk', 'Eggs', 'Flour']);
  });
}
