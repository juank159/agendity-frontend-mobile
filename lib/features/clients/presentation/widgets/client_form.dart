import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../controllers/client_form_controller.dart';
import 'client_image_picker.dart';

/// Campos del cliente, comunes al alta y a la edición.
class ClientForm extends StatelessWidget {
  final ClientFormController controller;

  const ClientForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientImagePicker(controller: controller),
        const SizedBox(height: 24),
        Text('Información básica', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _field(controller.nameController, 'Nombre *', Icons.person_outline,
            capitalization: TextCapitalization.words),
        _field(controller.lastnameController, 'Apellido', Icons.person_outline,
            capitalization: TextCapitalization.words),
        _field(
            controller.phoneController, 'Teléfono móvil *', Icons.phone_android,
            keyboard: TextInputType.phone),
        _field(controller.emailController, 'Email', Icons.email_outlined,
            keyboard: TextInputType.emailAddress),
        _field(controller.addressController, 'Dirección', Icons.home_outlined,
            keyboard: TextInputType.streetAddress),
        const SizedBox(height: 12),
        Text('Información adicional', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _field(controller.notesController, 'Notas del cliente',
            Icons.note_outlined,
            maxLines: 3),
        Obx(() => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.visibility_outlined),
              title: const Text('Mostrar notas en cada cita'),
              value: controller.showNotes.value,
              onChanged: (value) => controller.showNotes.value = value,
            )),
        Obx(() {
          final birthday = controller.birthday.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Cumpleaños'),
            subtitle:
                Text(birthday == null ? 'Sin fecha' : formatDate(birthday)),
            trailing: birthday == null
                ? const Icon(Icons.calendar_today)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Quitar fecha',
                    onPressed: () => controller.birthday.value = null,
                  ),
            onTap: () => _pickBirthday(context),
          );
        }),
      ],
    );
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final today = BusinessTimeZone.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.birthday.value ?? DateTime(today.year - 30),
      firstDate: DateTime(1900),
      lastDate: today,
      currentDate: today,
      helpText: 'Cumpleaños',
    );
    if (picked != null) {
      controller.birthday.value =
          DateTime(picked.year, picked.month, picked.day);
    }
  }

  Widget _field(
    TextEditingController textController,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: textController,
          keyboardType: keyboard,
          textCapitalization: capitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
