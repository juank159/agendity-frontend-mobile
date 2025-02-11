import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../controllers/appointments_controller.dart';

class ViewSelectorBottomSheet extends StatelessWidget {
  final AppointmentsController controller;

  const ViewSelectorBottomSheet({
    Key? key,
    required this.controller,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, AppointmentsController controller) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => ViewSelectorBottomSheet(controller: controller),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Seleccionar Vista',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 1),
        _buildViewOption(
          context: context,
          title: 'Vista Día',
          subtitle: 'Ver las citas del día',
          icon: Icons.view_day,
          view: CalendarView.day,
          currentView: controller.currentView.value,
        ),
        _buildViewOption(
          context: context,
          title: 'Vista Semana',
          subtitle: 'Ver las citas de la semana',
          icon: Icons.view_week,
          view: CalendarView.week,
          currentView: controller.currentView.value,
        ),
        _buildViewOption(
          context: context,
          title: 'Vista Mes',
          subtitle: 'Ver el calendario mensual',
          icon: Icons.calendar_view_month,
          view: CalendarView.month,
          currentView: controller.currentView.value,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildViewOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required CalendarView view,
    required CalendarView currentView,
  }) {
    final isSelected = currentView == view;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          controller.changeView(view);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.grey[100] : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
