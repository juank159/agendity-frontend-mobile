import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/config/utils/string_utils.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/whatsapp_icon.dart';
import '../controllers/edit_client_controller.dart';
import '../widgets/client_form.dart';
import '../widgets/client_image_picker.dart';

/// Ficha del cliente: cabecera con su foto, nombre y teléfono, "Llamar" y
/// "WhatsApp", el consentimiento de WhatsApp y el formulario para editarlo.
/// Borrar solo lo ve el Owner.
class EditClientScreen extends GetView<EditClientController> {
  const EditClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar cliente')),
      body: Obx(() {
        switch (controller.status.value) {
          case EditClientStatus.loading:
            return const LoadingState(message: 'Cargando cliente…');
          case EditClientStatus.error:
            return ErrorState(
              title: 'No se pudo cargar',
              message: controller.loadError.value ?? '',
              onRetry: controller.load,
            );
          case EditClientStatus.ready:
            return const _EditClientBody();
        }
      }),
    );
  }
}

class _EditClientBody extends GetView<EditClientController> {
  const _EditClientBody();

  @override
  Widget build(BuildContext context) {
    final error = context.tokens.error.color;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppFadeIn(child: _ClientHeader()),
            const _ConsentAction(),
            AppFadeIn(
              index: 1,
              child: ClientForm(controller: controller, showPhoto: false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Obx(() {
                final busy = controller.isDeleting.value ||
                    controller.isUploadingImage.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppGradientButton(
                      label: 'Guardar cambios',
                      icon: Icons.check_rounded,
                      expand: true,
                      loading: controller.isSaving.value,
                      onPressed: busy ? null : controller.submit,
                    ),
                    if (controller.canDelete) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: busy || controller.isSaving.value
                            ? null
                            : controller.delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: error,
                          side: BorderSide(color: error),
                        ),
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Eliminar cliente'),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabecera de la ficha: foto (se cambia tocándola), nombre y teléfono
/// guardados, y "Llamar"/"WhatsApp" si tiene teléfono (Owner y Employee).
class _ClientHeader extends GetView<EditClientController> {
  const _ClientHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      depth: 2,
      child: Obx(() {
        final client = controller.client.value;
        final phone = controller.savedPhone;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClientImagePicker(controller: controller, radius: 44),
            const SizedBox(height: 12),
            if (client != null)
              Text(client.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: scheme.onSurface)),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(StringUtils.formatPhoneNumber(phone),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)
                      .tabular),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: controller.callClient,
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Llamar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: controller.writeOnWhatsapp,
                      icon: WhatsappIcon(
                          color: scheme.onSecondaryContainer, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

/// Consentimiento de WhatsApp (11.06): "Ya aceptó" o el botón para pedirlo
/// por WhatsApp con el link de un solo uso.
class _ConsentAction extends GetView<EditClientController> {
  const _ConsentAction();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.savedWhatsappOptIn.value == true) {
        return const AppNote(
          'Ya aceptó recibir recordatorios por WhatsApp',
          key: Key('client-consent-accepted'),
          tone: AppTone.success,
          icon: Icons.verified_rounded,
          margin: EdgeInsets.fromLTRB(16, 8, 16, 4),
        );
      }
      if (!controller.canRequestConsent) return const SizedBox.shrink();
      final busy = controller.isRequestingConsent.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: OutlinedButton.icon(
          key: const Key('client-request-consent'),
          onPressed: busy ? null : controller.requestConsent,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.mark_chat_read_rounded),
          label: const Text('Pedir consentimiento por WhatsApp'),
        ),
      );
    });
  }
}
