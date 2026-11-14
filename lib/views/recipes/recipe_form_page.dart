import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../models/recipe.dart';
import '../../models/recipe_type.dart';
import '../../viewmodels/recipe_form_view_model.dart';
import '../widgets/recipe_image.dart';
import 'editable_list_field.dart';

/// Create a recipe, or edit [Recipe] when one is passed to [route].
/// Pops with the saved recipe.
class RecipeFormPage extends StatefulWidget {
  const RecipeFormPage({super.key});

  static Route<Recipe> route({Recipe? recipe}) {
    return MaterialPageRoute<Recipe>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => RecipeFormViewModel(
          recipeRepository: locator(),
          recipeTypeRepository: locator(),
          imageStorage: locator(),
          initial: recipe,
        ),
        child: const RecipeFormPage(),
      ),
    );
  }

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _save(RecipeFormViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final saved = await viewModel.save();
    if (!mounted || saved == null) return;
    Navigator.of(context).pop(saved);
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes to this recipe will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  void _showError(RecipeFormViewModel viewModel) {
    final message = viewModel.errorMessage;
    if (message == null) return;
    viewModel.clearError();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipeFormViewModel>();
    _showError(viewModel);

    return PopScope<Recipe>(
      canPop: !viewModel.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(viewModel.isEditing ? 'Edit recipe' : 'New recipe'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<RecipeType>>(
            future: viewModel.recipeTypes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Could not load recipe types.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildForm(viewModel, snapshot.requireData);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(RecipeFormViewModel viewModel, List<RecipeType> types) {
    const gap = SizedBox(height: 20);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          // Keeps lines readable on tablets and in landscape.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImagePickerSection(viewModel: viewModel),
                gap,
                TextFormField(
                  initialValue: viewModel.title,
                  decoration: const InputDecoration(labelText: 'Recipe name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: viewModel.setTitle,
                  validator: viewModel.validateTitle,
                ),
                gap,
                DropdownButtonFormField<int>(
                  initialValue: viewModel.typeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Recipe type'),
                  items: [
                    for (final type in types)
                      DropdownMenuItem(value: type.id, child: Text(type.name)),
                  ],
                  onChanged: viewModel.setType,
                  validator: viewModel.validateType,
                ),
                gap,
                _sectionField(
                  viewModel,
                  RecipeSection.ingredients,
                  label: 'Ingredients',
                  hintText: 'e.g. 2 cups flour',
                ),
                gap,
                _sectionField(
                  viewModel,
                  RecipeSection.steps,
                  label: 'Steps',
                  hintText: 'Describe the next step',
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: viewModel.isSaving ? null : () => _save(viewModel),
                  icon: viewModel.isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    viewModel.isEditing ? 'Save changes' : 'Save recipe',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wraps the list editor in a FormField so Form.validate() also checks
  /// that the list is not empty.
  Widget _sectionField(
    RecipeFormViewModel viewModel,
    RecipeSection section, {
    required String label,
    required String hintText,
  }) {
    return FormField<void>(
      validator: (_) => viewModel.validateItems(section),
      builder: (field) {
        void afterChange() {
          // Clear the error as soon as the list becomes valid.
          if (field.hasError) field.validate();
        }

        return EditableListField(
          label: label,
          hintText: hintText,
          items: viewModel.items(section),
          numbered: section == RecipeSection.steps,
          errorText: field.errorText,
          onAdd: (value) {
            viewModel.addItem(section, value);
            afterChange();
          },
          onEdit: (index, value) => viewModel.updateItem(section, index, value),
          onRemove: (index) => viewModel.removeItem(section, index),
          onReorder: (oldIndex, newIndex) =>
              viewModel.moveItem(section, oldIndex, newIndex),
        );
      },
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({required this.viewModel});

  final RecipeFormViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: RecipeImage(imagePath: viewModel.imagePath),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => viewModel.pickImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
            OutlinedButton.icon(
              onPressed: () => viewModel.pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
            if (viewModel.imagePath != null)
              TextButton.icon(
                onPressed: viewModel.removeImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove photo'),
              ),
          ],
        ),
      ],
    );
  }
}
