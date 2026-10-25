import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import '../controllers/whatsapp_controller.dart';
import '../widgets/whatsapp_setup_guide.dart';

/// Avisos de citas al WhatsApp del Owner vía CallMeBot. El envío al cliente
/// es manual (`wa.me`, `whatsapp_launcher`); esta pantalla no lo configura.
///
/// Es una sola configuración, no una lista: usa `LoadingState`/`ErrorState`
/// directamente en lugar de `ListStateView`.
class WhatsappConfigScreen extends GetView<WhatsappController> {
  const WhatsappConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp')),
      body: Obx(() {
        switch (controller.status.value) {
          case WhatsappLoadStatus.loading:
            return const LoadingState(message: 'Cargando configuración…');
          case WhatsappLoadStatus.error:
            final isFinal = controller.loadErrorIsFinal.value;
            return ErrorState(
              title: isFinal ? 'Sin acceso' : 'No se pudo cargar',
              icon: isFinal ? Icons.lock_outline : Icons.error_outline,
              message: controller.loadError.value ?? '',
              onRetry: isFinal ? null : controller.load,
            );
          case WhatsappLoadStatus.ready:
            return const _WhatsappContent();
        }
      }),
    );
  }
}

class _WhatsappContent extends GetView<WhatsappController> {
  const _WhatsappContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Avisos de citas en tu WhatsApp',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Conecta tu número con CallMeBot para recibir avisos de las '
                'citas. Los recordatorios a tus clientes se envían desde cada '
                'cita con el botón de WhatsApp.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (controller.showForm) ...[
                const WhatsappSetupGuide(),
                const SizedBox(height: 24),
                const _ConfigForm(),
              ] else
                const _ConfigSummary(),
            ],
          )),
    );
  }
}

/// Configuración guardada, con sus acciones.
class _ConfigSummary extends GetView<WhatsappController> {
  const _ConfigSummary();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Obx(() {
      final config = controller.config.value!;
      final state = config.isEnabled ? tokens.success : tokens.warning;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configuración actual',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Número de WhatsApp',
                    value: '+${WhatsappController.countryCode} '
                        '${WhatsappController.nationalPhoneNumber(config.phoneNumber)}',
                  ),
                  const Divider(),
                  const _InfoRow(
                    icon: Icons.key_outlined,
                    label: 'API Key',
                    value: '••••••',
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: config.isEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    label: 'Estado',
                    value: config.isEnabled ? 'Activado' : 'Desactivado',
                    valueColor: state.color,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.isBusy ? null : controller.startEditing,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isBusy || !config.isEnabled
                      ? null
                      : controller.sendTestMessage,
                  icon: controller.isSendingTest.value
                      ? const _ButtonSpinner()
                      : const Icon(Icons.send_outlined),
                  label: const Text('Enviar prueba'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.isBusy ? null : controller.toggleEnabled,
            style: TextButton.styleFrom(
              foregroundColor: config.isEnabled ? scheme.error : null,
            ),
            icon: Icon(config.isEnabled
                ? Icons.notifications_off_outlined
                : Icons.notifications_active_outlined),
            label:
                Text(config.isEnabled ? 'Desactivar avisos' : 'Activar avisos'),
          ),
        ],
      );
    });
  }
}

/// Alta (sin configuración) o edición.
class _ConfigForm extends GetView<WhatsappController> {
  const _ConfigForm();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('whatsapp-phone'),
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Tu número de WhatsApp',
                hintText: '3001234567',
                prefixText: '+${WhatsappController.countryCode} ',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('whatsapp-apikey'),
              controller: controller.apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key de CallMeBot',
                prefixIcon: Icon(Icons.key_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recibir avisos'),
              value: controller.formEnabled.value,
              onChanged: (value) => controller.formEnabled.value = value,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.isBusy ? null : controller.saveForm,
              icon: controller.isSaving.value
                  ? const _ButtonSpinner()
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar configuración'),
            ),
            if (controller.isEditing.value) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.isBusy ? null : controller.cancelEditing,
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}
