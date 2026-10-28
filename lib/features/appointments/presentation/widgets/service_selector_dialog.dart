import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/shared/utils/color_hex.dart';

/// Elige los servicios de una cita (al menos uno). Devuelve los ids en el
/// orden en que se marcaron, o `null` si se cancela.
class ServiceSelectorDialog extends StatefulWidget {
  final List<ServiceEntity> catalog;
  final List<String> selectedIds;

  const ServiceSelectorDialog({
    super.key,
    required this.catalog,
    this.selectedIds = const [],
  });

  static Future<List<String>?> show(List<ServiceEntity> catalog,
          {List<String> selectedIds = const []}) =>
      Get.dialog<List<String>>(
          ServiceSelectorDialog(catalog: catalog, selectedIds: selectedIds));

  @override
  State<ServiceSelectorDialog> createState() => _ServiceSelectorDialogState();
}

class _ServiceSelectorDialogState extends State<ServiceSelectorDialog> {
  final _search = TextEditingController();
  late final List<String> _selected = [...widget.selectedIds];
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) => setState(
      () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id));

  double get _total => widget.catalog
      .where((s) => _selected.contains(s.id))
      .fold(0, (sum, s) => sum + s.price);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = widget.catalog
        .where((s) => s.id != null && s.name.toLowerCase().contains(query))
        .toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Elegir servicios', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Buscar servicio',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        message: widget.catalog.isEmpty
                            ? 'No hay servicios activos'
                            : 'Ningún servicio coincide',
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final service = filtered[index];
                          final id = service.id!;
                          return CheckboxListTile(
                            value: _selected.contains(id),
                            onChanged: (_) => _toggle(id),
                            secondary: CircleAvatar(
                              radius: 8,
                              backgroundColor: colorFromHex(service.color),
                            ),
                            title: Text(service.name),
                            subtitle: Text(
                                '${formatCop(service.price)} · '
                                '${formatDurationMinutes(service.duration)}'),
                          );
                        },
                      ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatCount(_selected.length, 'servicio', 'servicios')}'
                      ' · ${formatCop(_total)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(List.of(_selected)),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
