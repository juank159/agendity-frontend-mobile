import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Elige la vista de la agenda: día, semana o mes.
class ViewSelectorBottomSheet extends StatelessWidget {
  final AppointmentsController controller;

  const ViewSelectorBottomSheet({super.key, required this.controller});

  static Future<void> show(AppointmentsController controller) =>
      Get.bottomSheet<void>(
        ViewSelectorBottomSheet(controller: controller),
        backgroundColor: Get.theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      );

  static const _options = [
    (CalendarView.day, Icons.view_day_outlined, 'Día', 'Las citas de un día'),
    (CalendarView.week, Icons.view_week_outlined, 'Semana', 'De lunes a domingo'),
    (CalendarView.month, Icons.calendar_view_month, 'Mes', 'Citas por día del mes'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = controller.currentView.value;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Vista de la agenda',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final (view, icon, title, subtitle) in _options)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
              selected: view == current,
              trailing: view == current
                  ? Icon(Icons.check_circle, color: scheme.primary)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                if (view != current) controller.changeView(view);
              },
            ),
          const Divider(),
          Obx(() => SwitchListTile(
                secondary: const Icon(Icons.event_busy_outlined),
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
