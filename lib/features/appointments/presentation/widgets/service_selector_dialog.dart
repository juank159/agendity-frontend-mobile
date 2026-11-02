import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';
import 'package:login_signup/shared/widgets/app_search_field.dart';

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
    final scheme = theme.colorScheme;
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppDialogTitle(
                icon: Icons.spa_rounded,
                title: 'Elegir servicios',
                subtitle: 'Puedes marcar varios: el total es la suma.',
              ),
              const SizedBox(height: 14),
              AppSearchField(
                controller: _search,
                hint: 'Buscar servicio',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
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
                          final checked = _selected.contains(id);
                          final color = colorFromHex(service.color);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: CheckboxListTile(
                              value: checked,
                              onChanged: (_) => _toggle(id),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.fieldRadius,
                                side: BorderSide(
                                    color: checked
                                        ? color.withValues(alpha: 0.7)
                                        : scheme.outlineVariant
                                            .withValues(alpha: 0.5)),
                              ),
                              tileColor: checked
                                  ? color.withValues(alpha: 0.12)
                                  : scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                              secondary: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: context.tokens
                                      .elevation1(tint: color),
                                ),
                              ),
                              title: Text(service.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${formatCop(service.price)} · '
                                '${formatDurationMinutes(service.duration)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant)
                                    .tabular,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatCount(_selected.length, 'servicio', 'servicios')}'
                      ' · ${formatCop(_total)}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)
                          .tabular,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  AppGradientButton(
                    label: 'Listo',
                    icon: Icons.check_rounded,
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(List.of(_selected)),
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
