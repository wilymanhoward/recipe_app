import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../data/local/image_storage.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/recipe_type_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_type.dart';

enum RecipeSection { ingredients, steps }

/// State for the create/edit form. With [initial] it edits that recipe,
/// otherwise it creates a new one.
class RecipeFormViewModel extends ChangeNotifier {
  RecipeFormViewModel({
    // Private named parameters: callers still write `recipeRepository:`.
    required this._recipeRepository,
    required RecipeTypeRepository recipeTypeRepository,
    required this._imageStorage,
    Recipe? initial,
  }) : _initial = initial,
       recipeTypes = recipeTypeRepository.getAll(),
       _title = initial?.title ?? '',
       _typeId = initial?.typeId,
       _imagePath = initial?.imagePath,
       _items = {
         RecipeSection.ingredients: [...?initial?.ingredients],
         RecipeSection.steps: [...?initial?.steps],
       };

  final RecipeRepository _recipeRepository;
  final ImageStorage _imageStorage;
  final Recipe? _initial;
  final Future<List<RecipeType>> recipeTypes;

  String _title;
  int? _typeId;
  String? _imagePath;
  final Map<RecipeSection, List<String>> _items;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isDisposed = false;
  String? _errorMessage;

  bool get isEditing => _initial != null;
  String get title => _title;
  int? get typeId => _typeId;
  String? get imagePath => _imagePath;
  bool get isSaving => _isSaving;

  /// Message for a failed pick or save, shown once by the view.
  String? get errorMessage => _errorMessage;

  /// True when leaving now would lose the user's edits.
  bool get hasUnsavedChanges => _hasChanges && !_isSaved;

  List<String> items(RecipeSection section) =>
      List.unmodifiable(_items[section]!);

  void setTitle(String value) {
    _title = value;
    _changed();
  }

  void setType(int? typeId) {
    _typeId = typeId;
    _changed();
  }

  void addItem(RecipeSection section, String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    _items[section]!.add(value);
    _changed();
  }

  void updateItem(RecipeSection section, int index, String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    _items[section]![index] = value;
    _changed();
  }

  void removeItem(RecipeSection section, int index) {
    _items[section]!.removeAt(index);
    _changed();
  }

  void moveItem(RecipeSection section, int oldIndex, int newIndex) {
    final list = _items[section]!;
    list.insert(newIndex, list.removeAt(oldIndex));
    _changed();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final path = await _imageStorage.pick(source);
      if (path == null) return;
      if (_isDisposed) {
        // The form was closed while the picker was open.
        unawaited(_imageStorage.delete(path));
        return;
      }
      _replaceImage(path);
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'Could not load that photo.';
      notifyListeners();
    }
  }

  void removeImage() => _replaceImage(null);

  void clearError() => _errorMessage = null;

  String? validateTitle(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter a recipe name' : null;

  String? validateType(int? value) =>
      value == null ? 'Choose a recipe type' : null;

  String? validateItems(RecipeSection section) {
    if (_items[section]!.isNotEmpty) return null;
    return section == RecipeSection.ingredients
        ? 'Add at least one ingredient'
        : 'Add at least one step';
  }

  /// Returns the saved recipe, or null if saving failed or the form is
  /// incomplete (then [errorMessage] says why).
  Future<Recipe?> save() async {
    final typeId = _typeId;
    if (_isSaving) return null;
    if (validateTitle(_title) != null ||
        typeId == null ||
        validateItems(RecipeSection.ingredients) != null ||
        validateItems(RecipeSection.steps) != null) {
      _errorMessage = 'Please complete the highlighted fields.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final initial = _initial;
      final recipe = Recipe(
        id: initial?.id,
        title: _title.trim(),
        typeId: typeId,
        imagePath: _imagePath,
        ingredients: List.of(_items[RecipeSection.ingredients]!),
        steps: List.of(_items[RecipeSection.steps]!),
        createdAt: initial?.createdAt ?? DateTime.now(),
        // The form doesn't show this flag, so carry it over unchanged.
        isFavourite: initial?.isFavourite ?? false,
      );

      final Recipe saved;
      if (initial == null) {
        saved = await _recipeRepository.insert(recipe);
      } else {
        await _recipeRepository.update(recipe);
        saved = recipe;
        // Only now is the old photo no longer referenced by the database.
        final oldImage = initial.imagePath;
        if (oldImage != null && oldImage != _imagePath) {
          unawaited(_imageStorage.delete(oldImage));
        }
      }
      _isSaved = true;
      return saved;
    } catch (_) {
      _errorMessage = 'Could not save the recipe. Please try again.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _replaceImage(String? path) {
    _deleteIfUnsaved(_imagePath);
    _imagePath = path;
    _changed();
  }

  /// Deletes a photo picked in this form that the database never saw.
  /// The recipe's original photo is kept until the edit is saved.
  void _deleteIfUnsaved(String? path) {
    if (path != null && path != _initial?.imagePath) {
      unawaited(_imageStorage.delete(path));
    }
  }

  void _changed() {
    _hasChanges = true;
    notifyListeners();
  }

  @override
  void dispose() {
    // Leaving without saving: clean up any photo picked in this form.
    if (!_isSaved) _deleteIfUnsaved(_imagePath);
    _isDisposed = true;
    super.dispose();
  }
}
