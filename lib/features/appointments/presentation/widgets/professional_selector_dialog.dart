import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_dialog_title.dart';
import 'package:login_signup/shared/widgets/app_search_field.dart';

/// Elige el profesional de una cita entre los que se pueden agendar
/// (activos y sin baja). Devuelve el elegido o `null` si se cierra.
class ProfessionalSelectorDialog extends StatefulWidget {
  final List<EmployeeEntity> options;
  final String? selectedId;

  const ProfessionalSelectorDialog({
    super.key,
    required this.options,
    this.selectedId,
  });

  static Future<EmployeeEntity?> show(List<EmployeeEntity> options,
          {String? selectedId}) =>
      Get.dialog<EmployeeEntity>(
          ProfessionalSelectorDialog(options: options, selectedId: selectedId));

  @override
  State<ProfessionalSelectorDialog> createState() =>
      _ProfessionalSelectorDialogState();
}

class _ProfessionalSelectorDialogState
    extends State<ProfessionalSelectorDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final filtered = widget.options
        .where((e) => e.fullName.toLowerCase().contains(query))
        .toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppDialogTitle(
                icon: Icons.person_rounded,
                title: 'Elegir profesional',
                subtitle: 'Solo los que están activos para agendar.',
              ),
              const SizedBox(height: 14),
              AppSearchField(
                controller: _search,
                hint: 'Buscar profesional',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.person_off_rounded,
                        message: widget.options.isEmpty
                            ? 'No hay profesionales disponibles'
                            : 'Ningún profesional coincide',
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final employee = filtered[index];
                          final selected = employee.id == widget.selectedId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.fieldRadius,
                                side: BorderSide(
                                    color: selected
                                        ? scheme.primary
                                        : scheme.outlineVariant
                                            .withValues(alpha: 0.5)),
                              ),
                              tileColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              selectedTileColor: scheme.primaryContainer,
                              leading: AppAvatar(
                                  name: employee.fullName,
                                  imageUrl: employee.image,
                                  radius: 20),
                              title: Text(employee.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              selected: selected,
                              trailing: selected
                                  ? Icon(Icons.check_circle_rounded,
                                      color: scheme.primary)
                                  : const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(context).pop(employee),
                            ),
                          );
                        },
                      ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
