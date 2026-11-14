import 'dart:convert';

class Recipe {
  const Recipe({
    this.id,
    required this.title,
    required this.typeId,
    this.imagePath,
    required this.ingredients,
    required this.steps,
    required this.createdAt,
  });

  factory Recipe.fromMap(Map<String, Object?> map) {
    return Recipe(
      id: map['id'] as int?,
      title: map['title']! as String,
      typeId: map['type_id']! as int,
      imagePath: map['image_path'] as String?,
      ingredients: _decodeList(map['ingredients']! as String),
      steps: _decodeList(map['steps']! as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    );
  }

  /// Null until the recipe has been saved to the database.
  final int? id;
  final String title;
  final int typeId;

  /// Absolute path of the photo in the app's documents folder, or null.
  final String? imagePath;
  final List<String> ingredients;
  final List<String> steps;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'type_id': typeId,
      'image_path': imagePath,
      'ingredients': jsonEncode(ingredients),
      'steps': jsonEncode(steps),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Recipe copyWith({
    int? id,
    String? title,
    int? typeId,
    String? imagePath,
    List<String>? ingredients,
    List<String>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      typeId: typeId ?? this.typeId,
      imagePath: imagePath ?? this.imagePath,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      createdAt: createdAt,
    );
  }

  static List<String> _decodeList(String source) {
    return (jsonDecode(source) as List<dynamic>).cast<String>();
  }
}
