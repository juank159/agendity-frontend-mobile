import 'package:flutter/material.dart';

/// Campo de búsqueda de las listas (guía §3): relleno, ícono de lupa al
/// inicio y botón de borrar cuando hay texto. El [controller] es del
/// `GetxController` de la lista (él lo libera); [onChanged] recibe cada
/// cambio y [onClear] borra la búsqueda (si no se pasa, se vacía el campo y
/// se avisa con `onChanged('')`). Lo usan clientes y profesionales.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String clearTooltip;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
    this.clearTooltip = 'Borrar búsqueda',
  });

  void _clear() {
    final clear = onClear;
    if (clear != null) {
      clear();
      return;
    }
    controller.clear();
    onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: clearTooltip,
                  onPressed: _clear,
                ),
        ),
      ),
    );
  }
}
