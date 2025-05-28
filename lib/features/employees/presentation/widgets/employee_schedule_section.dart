import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeeScheduleSection extends StatelessWidget {
  final EmployeesController controller;

  const EmployeeScheduleSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    return Obx(() => Column(
          children: controller.weekdays.map((day) {
            // Verificar si este día está habilitado
            final bool isDayEnabled = controller.enabledDays.contains(day);

            // Obtener el horario del día (si existe)
            final daySchedule =
                controller.schedule[day] ?? {'start': '09:00', 'end': '18:00'};

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isDayEnabled
                      ? AppColors.primary.withOpacity(0.7)
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Fila para el día y el switch
                    Row(
                      children: [
                        // Icono y nombre del día
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: isDayEnabled
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dayNames[day] ?? day,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDayEnabled ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Switch para activar/desactivar el día
                        Switch(
                          value: isDayEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (value) {
                            controller.toggleDayEnabled(day, value);
                          },
                        ),
                      ],
                    ),

                    // Selección de horario (solo visible si el día está habilitado)
                    if (isDayEnabled)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isDayEnabled ? null : 0,
                        child: Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimeField(
                                    context: context,
                                    label: 'Hora de inicio',
                                    value: daySchedule['start'] ?? '09:00',
                                    onChanged: (value) => controller
                                        .updateSchedule(day, 'start', value),
                                  ),
                                ),
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text('a',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: _buildTimeField(
                                    context: context,
                                    label: 'Hora de fin',
                                    value: daySchedule['end'] ?? '18:00',
                                    onChanged: (value) => controller
                                        .updateSchedule(day, 'end', value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ));
  }

  Widget _buildTimeField({
    required BuildContext context,
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _parseTimeString(value),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onChanged(_formatTimeOfDay(picked));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.access_time, size: 16, color: AppColors.primary),
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
