import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeeScheduleSection extends StatelessWidget {
  final EmployeesController controller;

  const EmployeeScheduleSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeesController>(
      builder: (controller) {
        return Column(
          children: controller.weekdays.map((day) {
            return _buildDaySchedule(
              day: day,
              schedule: controller.schedule,
              onUpdate: controller.updateSchedule,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDaySchedule({
    required String day,
    required RxMap<String, Map<String, String>> schedule,
    required Function(String, String, String) onUpdate,
  }) {
    final dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    final localDay = dayNames[day] ?? day;

    return GetBuilder<EmployeesController>(
      builder: (controller) {
        final daySchedule =
            controller.schedule[day] ?? {'start': '09:00', 'end': '18:00'};

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    localDay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          label: 'Inicio',
                          value: daySchedule['start'] ?? '09:00',
                          onChanged: (value) => onUpdate(day, 'start', value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeField(
                          label: 'Fin',
                          value: daySchedule['end'] ?? '18:00',
                          onChanged: (value) => onUpdate(day, 'end', value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: Get.context!,
              initialTime: _parseTimeString(value),
            );
            if (picked != null) {
              onChanged(_formatTimeOfDay(picked));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value),
                const Icon(Icons.access_time, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
