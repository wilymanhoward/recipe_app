import 'package:material_ui/material_ui.dart';

import '../../models/recipe_type.dart';

/// Shared look for the recipe-type dropdown menus.
class TypeMenuStyle {
  TypeMenuStyle._();

  static final BorderRadius borderRadius = BorderRadius.circular(16);
  static const int elevation = 3;
  static const double maxHeight = 360;
  static const Widget icon = Icon(Icons.keyboard_arrow_down_rounded);

  /// In a DropdownButtonFormField the whole field is the button, and the
  /// theme's ButtonTheme.alignedDropdown removes the extra menu margin, so
  /// the open menu is exactly as wide as the field. The start padding lines
  /// the closed text up with the menu rows.
  static const EdgeInsetsDirectional fieldPadding = EdgeInsetsDirectional.only(
    start: 16,
  );
}

/// One row in the open menu, with a thin divider underneath. The selected
/// row gets a round check mark; its tinted background comes from the
/// theme's focusColor, because the menu focuses the selected item on open.
class TypeMenuItemLabel extends StatelessWidget {
  const TypeMenuItemLabel(
    this.label, {
    super.key,
    required this.selected,
    this.showDivider = true,
  });

  final String label;
  final bool selected;

  /// False for the last row, so the menu doesn't end with a line.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      // Fills the whole row height so the divider sits at the row's edge.
      height: kMinInteractiveDimension,
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.outlineVariant))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: selected
                    ? colors.onSecondaryContainer
                    : colors.onSurface,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle_outline_rounded,
              size: 22,
              color: colors.secondary,
            ),
        ],
      ),
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

  /// The form-field dropdown shows a null value as an empty field, so
  /// "All types" uses this id internally. Real type ids are positive.
  static const int _allTypes = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedTypeId ?? _allTypes;
    final options = <(int, String)>[
      (_allTypes, 'All types'),
      for (final type in types) (type.id, type.name),
    ];

    // Same structure as the form's type field, so both menus line up with
    // their field the same way.
    return DropdownButtonFormField<int>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Recipe type',
        contentPadding: TypeMenuStyle.fieldPadding,
      ),
      // Dropdowns default to titleMedium, which is a serif heading here.
      style: theme.textTheme.bodyLarge,
      icon: TypeMenuStyle.icon,
      borderRadius: TypeMenuStyle.borderRadius,
      elevation: TypeMenuStyle.elevation,
      menuMaxHeight: TypeMenuStyle.maxHeight,
      dropdownColor: theme.colorScheme.surfaceContainerLowest,
      onChanged: (id) => onChanged(id == _allTypes ? null : id),
      // What the closed field shows: the filter icon and plain text.
      selectedItemBuilder: (context) => [
        for (final (_, label) in options)
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
      ],
      items: [
        for (final (index, (id, label)) in options.indexed)
          DropdownMenuItem<int>(
            value: id,
            child: TypeMenuItemLabel(
              label,
              selected: id == selected,
              showDivider: index < options.length - 1,
            ),
          ),
      ],
    );
  }
}
