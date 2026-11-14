import 'package:material_ui/material_ui.dart';

import '../../models/recipe_type.dart';

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
          onChanged: onChanged,
          items: [
            const DropdownMenuItem<int?>(child: Text('All types')),
            for (final type in types)
              DropdownMenuItem<int?>(value: type.id, child: Text(type.name)),
          ],
        ),
      ),
    );
  }
}
