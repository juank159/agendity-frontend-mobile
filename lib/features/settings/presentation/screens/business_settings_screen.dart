import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/shared/widgets/business_time_zone_notice.dart';

/// Configuración del negocio (solo Owner): la zona horaria con la que la app
/// y el backend interpretan y muestran todas las horas del negocio (D-15).
class BusinessSettingsScreen extends GetView<BusinessSettingsController> {
  const BusinessSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del negocio')),
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
            return const _TimeZoneEditor();
        }
      }),
      bottomNavigationBar: Obx(() =>
          controller.status.value == BusinessSettingsStatus.ready
              ? const _SaveBar()
              : const SizedBox.shrink()),
    );
  }
}

class _TimeZoneEditor extends GetView<BusinessSettingsController> {
  const _TimeZoneEditor();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BusinessTimeZoneNotice(),
        const _CurrentZoneCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: controller.searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar zona',
              hintText: 'Ciudad en inglés, p. ej. Bogota o Caracas',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() => controller.query.value.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Borrar búsqueda',
                      onPressed: controller.clearSearch,
                    )),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: Obx(() => ListStateView<String>(
                isLoading: false,
                items: controller.filteredZones,
                emptyIcon: Icons.search_off,
                emptyMessage: 'Ninguna zona coincide',
                emptySubMessage:
                    'Busca por continente o ciudad en inglés, por ejemplo '
                    '"America" o "Caracas".',
                builder: (context, zones) => _ZoneList(zones: zones),
              )),
        ),
      ],
    );
  }
}

/// Zona guardada, su diferencia con UTC y la hora actual del negocio.
class _CurrentZoneCard extends GetView<BusinessSettingsController> {
  const _CurrentZoneCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final zone = controller.savedZone.value ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zona horaria del negocio',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                zone,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${controller.offsetOf(zone)} · Ahora: ${controller.nowIn(zone)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Las citas, los horarios, las horas libres, las estadísticas '
                'por día y los recordatorios usan esta zona, sin importar '
                'dónde esté el teléfono.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ZoneList extends GetView<BusinessSettingsController> {
  final List<String> zones;

  const _ZoneList({required this.zones});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: zones.length,
      itemBuilder: (context, index) {
        final zone = zones[index];
        return Obx(() {
          final selected = controller.selectedZone.value == zone;
          return ListTile(
            title: Text(zone),
            subtitle: Text(controller.offsetOf(zone)),
            selected: selected,
            trailing: selected
                ? Icon(Icons.check_circle, color: scheme.primary)
                : null,
            onTap: () => controller.select(zone),
          );
        });
      },
    );
  }
}

class _SaveBar extends GetView<BusinessSettingsController> {
  const _SaveBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final saving = controller.isSaving.value;
          final enabled = controller.hasChanges && !saving;
          return FilledButton.icon(
            onPressed: enabled ? controller.save : null,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(controller.hasChanges
                ? 'Guardar ${controller.selectedZone.value}'
                : 'Sin cambios'),
          );
        }),
      ),
    );
  }
}
