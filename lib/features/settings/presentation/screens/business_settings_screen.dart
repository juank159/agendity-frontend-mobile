import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/features/settings/presentation/widgets/opening_hours_editor.dart';
import 'package:login_signup/features/settings/presentation/widgets/time_zone_picker.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';
import 'package:login_signup/shared/widgets/business_time_zone_notice.dart';
import 'package:login_signup/shared/widgets/palette_swatch.dart';

/// "Mi negocio" (solo Owner): nombre, link público de reservas, horario de
/// apertura, zona horaria (D-15) con la que se interpretan y muestran todas
/// las horas del negocio, color del negocio (D-22) y acceso a los
/// recordatorios. Cada sección es una `AppSectionCard` (12.05).
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
              icon: isFinal
                  ? Icons.lock_rounded
                  : Icons.cloud_off_rounded,
              message: controller.loadError.value ?? '',
              onRetry: isFinal ? null : controller.load,
            );
          case BusinessSettingsStatus.ready:
            const sections = <Widget>[
              _NameCard(),
              _BookingLinkCard(),
              _OpeningHoursCard(),
              _TimeZoneCard(),
              _PaletteCard(),
              _RemindersLinkCard(),
            ];
            return ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 32),
              children: [
                const BusinessTimeZoneNotice(),
                for (var i = 0; i < sections.length; i++)
                  AppFadeIn(index: i, child: sections[i]),
              ],
            );
        }
      }),
    );
  }
}

class _NameCard extends GetView<BusinessSettingsController> {
  const _NameCard();

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.storefront_rounded,
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
              prefixIcon: Icon(Icons.badge_rounded),
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
                icon: const Icon(Icons.check_rounded),
                label: const Text('Guardar nombre'),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// "Color del negocio" (D-22): la paleta de todos los teléfonos del negocio
/// que no eligieron otra y el acento de la web de reservas.
class _PaletteCard extends GetView<BusinessSettingsController> {
  const _PaletteCard();

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.palette_rounded,
      title: 'Color del negocio',
      subtitle: 'Lo ven tu equipo y tus clientes en el link de reservas. '
          'Cada persona puede elegir otro para su teléfono en Apariencia.',
      child: Obx(() {
        final saving = controller.isSavingPalette.value;
        final current = controller.savedPalette ?? AppPalette.fallback;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaletteSwatchGrid(
              padding: EdgeInsets.zero,
              selected: current,
              onSelected: saving ? null : controller.savePalette,
            ),
            if (saving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        );
      }),
    );
  }
}

/// Link de reservas como un "boleto": el link en una franja con el
/// degradado de la paleta y, debajo, copiar, compartir, WhatsApp y abrir.
class _BookingLinkCard extends GetView<BusinessSettingsController> {
  const _BookingLinkCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return AppSectionCard(
      icon: Icons.link_rounded,
      title: 'Link de reservas',
      subtitle: 'Tus clientes eligen servicio, profesional y hora libre. '
          'Solo aparecen los servicios con "Se puede reservar en línea"; '
          'las reservas llegan a la agenda como pendientes.',
      child: Obx(() {
        final link = controller.bookingLink;
        if (link == null) {
          return Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ponle nombre al negocio para tener tu link.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                gradient: tokens.primaryGradient,
                borderRadius: AppRadii.fieldRadius,
                border: Border.all(color: tokens.innerBorder),
                boxShadow: tokens.elevation1(),
              ),
              foregroundDecoration: BoxDecoration(
                gradient: tokens.sheenGradient,
                borderRadius: AppRadii.fieldRadius,
              ),
              child: Row(
                children: [
                  Icon(Icons.public_rounded, color: tokens.onGradient),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(link,
                        key: const Key('booking-link'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: tokens.onGradient,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Builder(
                  builder: (context) => FilledButton.icon(
                    key: const Key('share-link'),
                    onPressed: () =>
                        controller.shareLink(origin: _originOf(context)),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Compartir'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.copyLink,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.shareByWhatsapp,
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
                TextButton.icon(
                  onPressed: controller.openLink,
                  icon: const Icon(Icons.open_in_new_rounded),
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

/// Rectángulo del botón en pantalla (ancla del menú en iPad y macOS).
Rect? _originOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Acceso a "Recordatorios" (Fase 11) desde "Mi negocio".
class _RemindersLinkCard extends StatelessWidget {
  const _RemindersLinkCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: EdgeInsets.zero,
      depth: 1,
      child: ListTile(
        key: const Key('business-reminders'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: AppRadii.chipRadius,
          ),
          child: Icon(Icons.notifications_active_rounded,
              size: 20, color: scheme.onPrimaryContainer),
        ),
        title: const Text('Recordatorios por WhatsApp',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Antes de la cita, mantenimiento, cumpleaños y '
            '"te extrañamos".'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Get.toNamed(GetRoutes.reminders),
      ),
    );
  }
}

class _OpeningHoursCard extends GetView<BusinessSettingsController> {
  const _OpeningHoursCard();

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.schedule_rounded,
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
            AnimatedSize(
              duration: AppMotion.of(context),
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: limited
                  ? OpeningHoursEditor(controller: controller)
                  : const SizedBox(width: double.infinity),
            ),
            if (controller.hoursChanged) ...[
              const SizedBox(height: 8),
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
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Guardar horario'),
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
    return AppSectionCard(
      icon: Icons.public_rounded,
      title: 'Zona horaria del negocio',
      subtitle: 'Las citas, los horarios, las horas libres, las estadísticas '
          'por día y los recordatorios usan esta zona, sin importar dónde '
          'esté el teléfono.',
      child: Obx(() {
        final zone = controller.savedZone ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: AppRadii.fieldRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ZonePill(
                            icon: Icons.language_rounded,
                            text: controller.offsetOf(zone)),
                        _ZonePill(
                            icon: Icons.access_time_rounded,
                            text: 'Ahora: ${controller.nowIn(zone)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: controller.isSavingZone.value ? null : _change,
                child: const Text('Cambiar'),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Dato corto de la zona ("UTC-05:00", "Ahora: 9:30 a. m.").
class _ZonePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ZonePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadii.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(text,
              style: theme.textTheme.labelMedium?.tabular
                  .copyWith(color: scheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}
