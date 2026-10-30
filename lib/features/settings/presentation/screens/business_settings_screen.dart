import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/features/settings/presentation/widgets/opening_hours_editor.dart';
import 'package:login_signup/features/settings/presentation/widgets/time_zone_picker.dart';
import 'package:login_signup/shared/widgets/business_time_zone_notice.dart';

/// "Mi negocio" (solo Owner): nombre, link público de reservas, horario de
/// apertura y zona horaria (D-15) con la que se interpretan y muestran todas
/// las horas del negocio.
class BusinessSettingsScreen extends GetView<BusinessSettingsController> {
  const BusinessSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi negocio')),
      body: Obx(() {
        switch (controller.status.value) {
          case BusinessSettingsStatus.loading:
            return const LoadingState(message: 'Cargando configuración…');
          case BusinessSettingsStatus.error:
            final isFinal = controller.loadErrorIsFinal.value;
            return ErrorState(
              title: isFinal ? 'Sin acceso' : 'No se pudo cargar',
              icon: isFinal ? Icons.lock_outline : Icons.error_outline,
              message: controller.loadError.value ?? '',
              onRetry: isFinal ? null : controller.load,
            );
          case BusinessSettingsStatus.ready:
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: const [
                BusinessTimeZoneNotice(),
                _NameCard(),
                _BookingLinkCard(),
                _OpeningHoursCard(),
                _TimeZoneCard(),
              ],
            );
        }
      }),
    );
  }
}

/// Tarjeta de sección con título e icono.
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NameCard extends GetView<BusinessSettingsController> {
  const _NameCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.storefront_outlined,
      title: 'Nombre del negocio',
      subtitle: 'Lo ven tus clientes en el link de reservas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('business-name'),
            controller: controller.nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          Obx(() {
            final saving = controller.isSavingName.value;
            return Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: controller.nameChanged && !saving
                    ? controller.saveName
                    : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar nombre'),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BookingLinkCard extends GetView<BusinessSettingsController> {
  const _BookingLinkCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      icon: Icons.link,
      title: 'Link de reservas',
      subtitle: 'Tus clientes eligen servicio, profesional y hora libre. '
          'Solo aparecen los servicios con "Se puede reservar en línea"; '
          'las reservas llegan a la agenda como pendientes.',
      child: Obx(() {
        final link = controller.bookingLink;
        if (link == null) {
          return Text(
            'Ponle nombre al negocio para tener tu link.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(link,
                key: const Key('booking-link'),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.copyLink,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.shareLink,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir por WhatsApp'),
                ),
                TextButton.icon(
                  onPressed: controller.openLink,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir'),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _OpeningHoursCard extends GetView<BusinessSettingsController> {
  const _OpeningHoursCard();

  @override
  Widget build(BuildContext context) {
    return _Section(
      icon: Icons.schedule,
      title: 'Horario de apertura',
      subtitle: 'Fuera de este horario no se agendan citas (ni en la app ni '
          'por el link). Un día sin franjas está cerrado.',
      child: Obx(() {
        final limited = controller.limitsHours.value;
        final saving = controller.isSavingHours.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const Key('opening-hours-enabled'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Limitar las citas a un horario'),
              subtitle: Text(limited
                  ? 'Activo'
                  : 'Sin horario: se agenda a cualquier hora'),
              value: limited,
              onChanged: controller.setLimitsHours,
            ),
            if (limited) OpeningHoursEditor(controller: controller),
            if (controller.hoursChanged)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: saving ? null : controller.discardHours,
                    child: const Text('Descartar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: saving ? null : controller.saveOpeningHours,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar horario'),
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }
}

/// Zona guardada, su diferencia con UTC y la hora actual del negocio.
class _TimeZoneCard extends GetView<BusinessSettingsController> {
  const _TimeZoneCard();

  Future<void> _change() async {
    final zone = await TimeZonePicker.show(controller);
    if (zone != null) await controller.saveTimeZone(zone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _Section(
      icon: Icons.public,
      title: 'Zona horaria del negocio',
      subtitle: 'Las citas, los horarios, las horas libres, las estadísticas '
          'por día y los recordatorios usan esta zona, sin importar dónde '
          'esté el teléfono.',
      child: Obx(() {
        final zone = controller.savedZone ?? '';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '${controller.offsetOf(zone)} · Ahora: '
                    '${controller.nowIn(zone)}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: controller.isSavingZone.value ? null : _change,
              child: const Text('Cambiar'),
            ),
          ],
        );
      }),
    );
  }
}
