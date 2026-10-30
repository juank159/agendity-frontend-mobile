import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';

/// Selector de zona horaria a pantalla completa, con búsqueda. Devuelve la
/// zona tocada o `null` si se cierra.
class TimeZonePicker extends StatelessWidget {
  final BusinessSettingsController controller;

  const TimeZonePicker({super.key, required this.controller});

  static Future<String?> show(BusinessSettingsController controller) {
    controller.clearSearch();
    return Get.dialog<String>(TimeZonePicker(controller: controller));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Zona horaria'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    builder: (context, zones) => ListView.builder(
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        final selected = zone == controller.savedZone;
                        return ListTile(
                          title: Text(zone),
                          subtitle: Text(controller.offsetOf(zone)),
                          selected: selected,
                          trailing: selected
                              ? Icon(Icons.check_circle, color: scheme.primary)
                              : null,
                          onTap: () => Navigator.of(context).pop(zone),
                        );
                      },
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
