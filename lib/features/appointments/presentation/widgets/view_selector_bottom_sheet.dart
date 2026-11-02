import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Opciones de la agenda en una hoja (`AppSheet`): la vista (día, semana o
/// mes; también en la barra del calendario) y "Mostrar canceladas".
class ViewSelectorBottomSheet extends StatelessWidget {
  final AppointmentsController controller;

  const ViewSelectorBottomSheet({super.key, required this.controller});

  static Future<void> show(
          BuildContext context, AppointmentsController controller) =>
      AppSheet.show<void>(
        context,
        title: 'Opciones de la agenda',
        icon: Icons.tune_rounded,
        builder: (_) => ViewSelectorBottomSheet(controller: controller),
      );

  static const _options = [
    (CalendarView.day, Icons.view_day_rounded, 'Día', 'Las citas de un día'),
    (
      CalendarView.week,
      Icons.view_week_rounded,
      'Semana',
      'De lunes a domingo'
    ),
    (
      CalendarView.month,
      Icons.calendar_view_month_rounded,
      'Mes',
      'Citas por día del mes'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = controller.currentView.value;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (view, icon, title, subtitle) in _options)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
              selected: view == current,
              trailing: view == current
                  ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                if (view != current) controller.changeView(view);
              },
            ),
          const Divider(indent: 16, endIndent: 16),
          Obx(() => SwitchListTile(
                secondary: const Icon(Icons.event_busy_rounded),
                title: const Text('Mostrar canceladas'),
                subtitle: const Text('Ocultas, no ocupan espacio en la agenda'),
                value: controller.showCancelled.value,
                onChanged: (_) => controller.toggleShowCancelled(),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
