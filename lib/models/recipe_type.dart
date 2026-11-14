import 'dart:convert';

class RecipeType {
  const RecipeType({required this.id, required this.name});

  factory RecipeType.fromJson(Map<String, dynamic> json) {
    return RecipeType(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;

  /// Parses the `recipetypes.json` format: `{"recipeTypes": [{"id": 1, "name": "..."}]}`.
  static List<RecipeType> listFromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final items = root['recipeTypes'] as List<dynamic>;
    return items
        .map((item) => RecipeType.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // DropdownButton matches its value against items with ==, so two instances
  // of the same type must compare equal.
  @override
  bool operator ==(Object other) => other is RecipeType && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RecipeType($id, $name)';
}
