import 'package:material_ui/material_ui.dart';

import '../../viewmodels/recipe_list_view_model.dart';

/// The search box, with the sort menu beside it.
class RecipeSearchBar extends StatelessWidget {
  const RecipeSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.sort,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final RecipeSort sort;
  final ValueChanged<RecipeSort> onSortChanged;

  static String sortLabel(RecipeSort sort) => switch (sort) {
    RecipeSort.newest => 'Newest first',
    RecipeSort.oldest => 'Oldest first',
    RecipeSort.name => 'Name (A to Z)',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          // Rebuilds as the text changes, to show the clear button only
          // when there is something to clear.
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              // Search is done as you type, so the keyboard's search key
              // just closes the keyboard.
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: 'Search name or ingredient',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: onClear,
                      ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<RecipeSort>(
          tooltip: 'Sort recipes',
          initialValue: sort,
          onSelected: onSortChanged,
          icon: const Icon(Icons.sort),
          // Looks like the fields beside and below it.
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            backgroundColor: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.outlineVariant),
            ),
          ),
          itemBuilder: (context) => [
            for (final option in RecipeSort.values)
              CheckedPopupMenuItem<RecipeSort>(
                value: option,
                checked: option == sort,
                child: Text(sortLabel(option)),
              ),
          ],
        ),
      ],
    );
  }
}
