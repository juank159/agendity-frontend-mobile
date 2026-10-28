import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_avatar.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Elegir profesional',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Buscar profesional',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.person_off_outlined,
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
                          return ListTile(
                            leading:
                                EmployeeAvatar(employee: employee, radius: 20),
                            title: Text(employee.fullName),
                            selected: selected,
                            trailing: selected
                                ? Icon(Icons.check_circle, color: scheme.primary)
                                : null,
                            onTap: () => Navigator.of(context).pop(employee),
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
