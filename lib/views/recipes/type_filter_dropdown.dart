import 'package:material_ui/material_ui.dart';

import '../../models/recipe_type.dart';

/// Shared look for the recipe-type dropdown menus.
class TypeMenuStyle {
  TypeMenuStyle._();

  static final BorderRadius borderRadius = BorderRadius.circular(16);
  static const int elevation = 3;
  static const double maxHeight = 360;
  static const Widget icon = Icon(Icons.keyboard_arrow_down_rounded);
}

/// One row in the open menu: the selected type is bold, in the accent
/// colour, with a check mark.
class TypeMenuItemLabel extends StatelessWidget {
  const TypeMenuItemLabel(this.label, {super.key, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: selected ? colors.primary : colors.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (selected)
          Icon(Icons.check_rounded, size: 20, color: colors.primary),
      ],
    );
  }
}

/// Dropdown populated from recipetypes.json, with an extra "All types"
/// entry. The selected value is a type id, or null for all types.
class TypeFilterDropdown extends StatelessWidget {
  const TypeFilterDropdown({
    super.key,
    required this.types,
    required this.selectedTypeId,
    required this.onChanged,
  });

  final List<RecipeType> types;
  final int? selectedTypeId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <(int?, String)>[
      (null, 'All types'),
      for (final type in types) (type.id, type.name),
    ];

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Recipe type',
        prefixIcon: Icon(Icons.filter_list),
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedTypeId,
          isExpanded: true,
          // Dropdowns default to titleMedium, which is a serif heading here.
          style: theme.textTheme.bodyLarge,
          icon: TypeMenuStyle.icon,
          borderRadius: TypeMenuStyle.borderRadius,
          elevation: TypeMenuStyle.elevation,
          menuMaxHeight: TypeMenuStyle.maxHeight,
          dropdownColor: theme.colorScheme.surfaceContainerLowest,
          onChanged: onChanged,
          // What the closed button shows: plain text, without the check mark.
          selectedItemBuilder: (context) => [
            for (final (_, label) in options)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
          ],
          items: [
            for (final (id, label) in options)
              DropdownMenuItem<int?>(
                value: id,
                child: TypeMenuItemLabel(label, selected: id == selectedTypeId),
              ),
          ],
        ),
      ),
    );
  }
}
