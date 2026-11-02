import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';
import '../controllers/client_form_controller.dart';
import 'client_image_picker.dart';

/// Campos del cliente, comunes al alta y a la edición, en secciones de la
/// guía: datos básicos, información adicional y WhatsApp. La foto va arriba
/// salvo que la pantalla la pinte en su cabecera ([showPhoto] en `false`,
/// la ficha).
class ClientForm extends StatelessWidget {
  final ClientFormController controller;
  final bool showPhoto;

  const ClientForm(
      {super.key, required this.controller, this.showPhoto = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPhoto) ...[
          const SizedBox(height: 8),
          ClientImagePicker(controller: controller),
          const SizedBox(height: 8),
        ],
        AppSectionCard(
          icon: Icons.person_rounded,
          title: 'Información básica',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(controller.nameController, 'Nombre *',
                  Icons.person_rounded,
                  capitalization: TextCapitalization.words),
              _field(controller.lastnameController, 'Apellido',
                  Icons.badge_rounded,
                  capitalization: TextCapitalization.words),
              _field(controller.phoneController, 'Teléfono móvil *',
                  Icons.phone_android_rounded,
                  keyboard: TextInputType.phone),
              _field(controller.emailController, 'Email', Icons.email_rounded,
                  keyboard: TextInputType.emailAddress),
              _field(controller.addressController, 'Dirección',
                  Icons.home_rounded,
                  keyboard: TextInputType.streetAddress, last: true),
            ],
          ),
        ),
        AppSectionCard(
          icon: Icons.sticky_note_2_rounded,
          title: 'Información adicional',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(controller.notesController, 'Notas del cliente',
                  Icons.notes_rounded,
                  maxLines: 3),
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.visibility_rounded),
                    title: const Text('Mostrar notas en cada cita'),
                    value: controller.showNotes.value,
                    onChanged: (value) => controller.showNotes.value = value,
                  )),
              Obx(() {
                final birthday = controller.birthday.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_rounded),
                  title: const Text('Cumpleaños'),
                  subtitle: Text(
                      birthday == null ? 'Sin fecha' : formatDate(birthday)),
                  trailing: birthday == null
                      ? const Icon(Icons.calendar_month_rounded)
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Quitar fecha',
                          onPressed: () => controller.birthday.value = null,
                        ),
                  onTap: () => _pickBirthday(context),
                );
              }),
            ],
          ),
        ),
        AppSectionCard(
          icon: Icons.mark_chat_read_rounded,
          title: 'Recordatorios por WhatsApp',
          child: Obx(() => CheckboxListTile(
                key: const Key('client-whatsapp-opt-in'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Acepta recibir recordatorios por WhatsApp'),
                subtitle: Text(_consentStatus()),
                value: controller.whatsappOptIn.value == true,
                onChanged: (value) =>
                    controller.setWhatsappOptIn(value ?? false),
              )),
        ),
      ],
    );
  }

  /// Estado del consentimiento (Ley 1581): pregúntale antes de marcarla.
  String _consentStatus() {
    final saved = controller.savedWhatsappOptIn.value;
    final acceptedAt = controller.whatsappOptInAt.value;
    final optedOutAt = controller.whatsappOptOutAt.value;
    if (saved == true) {
      final on = acceptedAt == null ? '' : ' el ${formatDate(acceptedAt)}';
      return switch (controller.whatsappOptInSource.value) {
        ConsentSource.link => 'Aceptó desde el link$on.',
        ConsentSource.app => 'Marcado por el negocio$on.',
        ConsentSource.web => 'Aceptó al reservar por la web$on.',
        _ => acceptedAt == null
            ? 'Aceptó recibir mensajes automáticos.'
            : 'Aceptó$on.',
      };
    }
    if (saved == false) {
      return optedOutAt == null
          ? 'Se dio de baja: no recibe mensajes automáticos.'
          : 'Se dio de baja el ${formatDate(optedOutAt)}: no recibe mensajes '
              'automáticos.';
    }
    return 'Márcala solo si el cliente te dio permiso. Sin ella no recibe '
        'recordatorios automáticos (solo los que envíes tú por WhatsApp).';
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
    bool last = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 12),
        child: TextField(
          controller: textController,
          keyboardType: keyboard,
          textCapitalization: capitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
          ),
        ),
      );
}
