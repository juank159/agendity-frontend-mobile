import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_avatar.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_schedule_section.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_status_ui.dart';

/// Detalle de un profesional (ruta `employeeDetails`, la entidad llega en
/// `arguments`). Solo lectura: las acciones están en la lista.
class EmployeeDetailsScreen extends StatelessWidget {
  final EmployeeEntity? employee;

  const EmployeeDetailsScreen({super.key, this.employee});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final employee =
        this.employee ?? (args is EmployeeEntity ? args : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del profesional')),
      body: employee == null
          ? const ErrorState(message: 'No se encontró el profesional.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(employee: employee),
                const SizedBox(height: 16),
                _Section(
                  icon: Icons.contact_mail_outlined,
                  title: 'Contacto',
                  children: [
                    _InfoRow(Icons.email_outlined, 'Email', employee.email),
                    _InfoRow(Icons.phone_outlined, 'Teléfono',
                        employee.phone.isEmpty ? 'Sin teléfono' : employee.phone),
                  ],
                ),
                _Section(
                  icon: Icons.spa_outlined,
                  title: 'Servicios (${employee.serviceAssignments.length})',
                  children: employee.serviceAssignments.isEmpty
                      ? const [Text('Sin servicios asignados')]
                      : [
                          for (final service
                              in employee.serviceAssignments.values)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.spa_outlined),
                              title: Text(service.serviceName ?? 'Servicio'),
                              subtitle: Text([
                                'Comisión ${formatPercent(service.commissionPercentage)}',
                                if (service.customPrice != null)
                                  'Precio propio ${formatCop(service.customPrice)}',
                              ].join(' · ')),
                            ),
                        ],
                ),
                _Section(
                  icon: Icons.schedule,
                  title: 'Horario',
                  children: employee.schedule.isEmpty
                      ? const [
                          Text('Sin horario: se le puede agendar a cualquier '
                              'hora.')
                        ]
                      : [
                          for (final day in WorkHours.weekdays)
                            if (employee.schedule[day] case final hours?)
                              _InfoRow(Icons.calendar_today_outlined,
                                  employeeDayLabels[day] ?? day,
                                  '${hours.start} a ${hours.end}'),
                        ],
                ),
                if (employee.isDeleted)
                  _Section(
                    icon: Icons.delete_outline,
                    title: 'Baja',
                    children: [
                      if (employee.deletedAt != null)
                        _InfoRow(Icons.event_busy_outlined, 'Fecha',
                            formatDate(employee.deletedAt!)),
                      _InfoRow(Icons.notes_outlined, 'Motivo',
                          employee.deletionReason ?? 'Sin motivo'),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final EmployeeEntity employee;

  const _Header({required this.employee});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        EmployeeAvatar(employee: employee, radius: 48),
        const SizedBox(height: 12),
        Text(employee.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            EmployeeStatusChip(status: employee.status),
            if (employee.isOwner) const OwnerChip(),
          ],
        ),
        const SizedBox(height: 8),
        Text(employee.status.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: muted)),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
