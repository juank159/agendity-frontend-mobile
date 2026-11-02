import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';

/// Diálogo para renombrar una categoría. Guardar lo hace [onSave] (el
/// controller): devuelve `true` si se guardó y entonces el diálogo se cierra;
/// si no, queda abierto con lo escrito (el error ya se avisó).
class EditCategoryDialog extends StatefulWidget {
  final CategoryEntity category;
  final Future<bool> Function(String name, String description) onSave;

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.onSave,
  });

  static Future<void> show({
    required CategoryEntity category,
    required Future<bool> Function(String name, String description) onSave,
  }) =>
      Get.dialog<void>(
        EditCategoryDialog(category: category, onSave: onSave),
        barrierDismissible: false,
      );

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category.name);
    _description = TextEditingController(text: widget.category.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final saved = await widget.onSave(_name.text, _description.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.edit_rounded),
      title: const Text('Editar categoría'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                prefixIcon: Icon(Icons.label_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppGradientButton(
          label: 'Guardar',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
