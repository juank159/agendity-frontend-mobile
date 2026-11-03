import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_hours_text.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Encima del calendario (D-25):
///
/// - el profesional del filtro ("Solo Ana Pérez", con una × para quitarlo);
/// - en la vista de día, si el negocio no atiende ese día (o el profesional
///   elegido no trabaja), un aviso claro: "Los domingos el negocio está
///   cerrado" y cuándo vuelve a abrir. Si aun así hay citas, se muestran.
class AgendaDayNotice extends GetView<AppointmentsController> {
  const AgendaDayNotice({super.key});

  static const closedKey = Key('agenda-closed-day');
  static const filterKey = Key('agenda-filter-chip');

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filtered = controller.filteredProfessionalName;
      final children = <Widget>[
        if (filtered != null)
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              key: filterKey,
              avatar: const Icon(Icons.person_search_rounded, size: 18),
              label: Text('Solo $filtered'),
              onDeleted: () => controller.filterByProfessional(null),
              deleteButtonTooltipMessage: 'Ver todo el equipo',
            ),
          ),
      ];
      if (controller.currentView.value == CalendarView.day) {
        final day = controller.dayHours(controller.selectedDate.value);
        if (day.open.isEmpty) {
          final hours = controller.hours.value;
          final today = controller.now();
          final who = controller.isEmployeeView ? '' : filtered;
          final next = AgendaHoursText.nextOpening(hours, day, today, who: who);
          final hasAppointments = controller.countOn(day.day) > 0;
          children.add(_ClosedDay(
            title: AgendaHoursText.closedDayTitle(day, today, who: who),
            lines: [
              if (next != null) next,
              if (hasAppointments) 'Las citas de este día se muestran igual.',
              'Este día no se pueden agendar citas.',
            ],
            icon: day.isClosed
                ? Icons.storefront_rounded
                : Icons.person_off_rounded,
          ));
        }
      }
      if (children.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              children[i],
            ],
          ],
        ),
      );
    });
  }
}

class _ClosedDay extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData icon;

  const _ClosedDay(
      {required this.title, required this.lines, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.tokens.tone(AppTone.warning);
    return Semantics(
      container: true,
      liveRegion: true,
      child: AppNote(
        title,
        key: AgendaDayNotice.closedKey,
        tone: AppTone.warning,
        icon: icon,
        trailing: Text(
          lines.join(' '),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onContainer, height: 1.35),
        ),
      ),
    );
  }
}
