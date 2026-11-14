import 'package:material_ui/material_ui.dart';

/// An editable list of text items (ingredients or steps): add with the text
/// field, tap an item to edit it, drag the handle to reorder, delete with
/// the bin icon.
class EditableListField extends StatefulWidget {
  const EditableListField({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    required this.numbered,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onReorder,
    this.errorText,
  });

  final String label;
  final String hintText;
  final List<String> items;

  /// Numbers the items (steps) instead of using bullets (ingredients).
  final bool numbered;
  final ValueChanged<String> onAdd;
  final void Function(int index, String value) onEdit;
  final ValueChanged<int> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String? errorText;

  @override
  State<EditableListField> createState() => _EditableListFieldState();
}

class _EditableListFieldState extends State<EditableListField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (_controller.text.trim().isEmpty) return;
    widget.onAdd(_controller.text);
    _controller.clear();
  }

  Future<void> _edit(int index) async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _EditItemDialog(
        title: 'Edit ${widget.numbered ? 'step' : 'ingredient'}',
        initialValue: widget.items[index],
      ),
    );
    if (value != null) widget.onEdit(index, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: widget.items.length,
          onReorderItem: widget.onReorder,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return ListTile(
              key: ValueKey('$index:$item'),
              contentPadding: EdgeInsets.zero,
              leading: widget.numbered
                  ? CircleAvatar(radius: 14, child: Text('${index + 1}'))
                  : const Icon(Icons.circle, size: 8),
              title: Text(item),
              onTap: () => _edit(index),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => widget.onRemove(index),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                // Single line so Enter adds the item instead of a newline.
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  errorText: errorText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Add',
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  const _EditItemDialog({required this.title, required this.initialValue});

  final String title;
  final String initialValue;

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
