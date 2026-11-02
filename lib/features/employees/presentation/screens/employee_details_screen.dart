import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_schedule_section.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_status_ui.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';

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
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                for (final (i, section) in _sections(employee).indexed)
                  AppFadeIn(index: i, child: section),
              ],
            ),
    );
  }

  List<Widget> _sections(EmployeeEntity employee) => [
        _Header(employee: employee),
        AppSectionCard(
          icon: Icons.contact_mail_rounded,
          title: 'Contacto',
          child: Column(
            children: [
              _InfoRow(Icons.email_rounded, 'Email', employee.email),
              _InfoRow(Icons.phone_rounded, 'Teléfono',
                  employee.phone.isEmpty ? 'Sin teléfono' : employee.phone),
            ],
          ),
        ),
        AppSectionCard(
          icon: Icons.spa_rounded,
          title: 'Servicios (${employee.serviceAssignments.length})',
          subtitle:
              'Comisión general ${formatPercent(employee.commissionPercentage)}',
          child: employee.serviceAssignments.isEmpty
              ? const Text('Sin servicios asignados')
              : Column(
                  children: [
                    for (final service in employee.serviceAssignments.values)
                      _ServiceRow(
                        name: service.serviceName ?? 'Servicio',
                        commission: formatPercent(service.effectiveCommission(
                            employee.commissionPercentage)),
                        customPrice: service.customPrice == null
                            ? null
                            : 'Precio propio ${formatCop(service.customPrice)}',
                      ),
                  ],
                ),
        ),
        AppSectionCard(
          icon: Icons.schedule_rounded,
          title: 'Horario',
          child: employee.schedule.isEmpty
              ? const Text('Sin horario: se le puede agendar a cualquier hora.')
              : Column(
                  children: [
                    for (final day in WorkHours.weekdays)
                      if (employee.schedule[day] case final hours?)
                        _InfoRow(
                            Icons.calendar_today_rounded,
                            employeeDayLabels[day] ?? day,
                            '${formatHhmm(hours.start)} – '
                                '${formatHhmm(hours.end)}'),
                  ],
                ),
        ),
        if (employee.isDeleted)
          AppSectionCard(
            icon: Icons.delete_rounded,
            title: 'Baja',
            child: Column(
              children: [
                if (employee.deletedAt != null)
                  _InfoRow(Icons.event_busy_rounded, 'Fecha',
                      formatDate(employee.deletedAt!)),
                _InfoRow(Icons.notes_rounded, 'Motivo',
                    employee.deletionReason ?? 'Sin motivo'),
              ],
            ),
          ),
      ];
}

/// Cabecera: avatar grande, nombre, estado (y Propietario) y qué significa
/// ese estado.
class _Header extends StatelessWidget {
  final EmployeeEntity employee;

  const _Header({required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      child: Column(
        children: [
          AppAvatar(
            name: employee.fullName,
            imageUrl: employee.image,
            radius: 44,
            muted: employee.status != EmployeeStatus.active,
          ),
          const SizedBox(height: 12),
          Text(employee.fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, color: scheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
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
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String name;
  final String commission;
  final String? customPrice;

  const _ServiceRow({
    required this.name,
    required this.commission,
    this.customPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final price = customPrice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.spa_rounded, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (price != null)
                  Text(price,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)
                          .tabular),
              ],
            ),
          ),
          AppPill(
            dense: true,
            tabular: true,
            icon: Icons.percent_rounded,
            label: 'Comisión $commission',
          ),
        ],
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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
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
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                Text(value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
