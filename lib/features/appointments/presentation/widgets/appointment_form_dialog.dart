import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import '../controllers/appointments_controller.dart';

import 'client_selector_dialog.dart';

class AppointmentFormDialog extends StatelessWidget {
  final AppointmentsController controller;

  const AppointmentFormDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    AppointmentsController controller,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AppointmentFormDialog(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final selectedServiceId = RxString('');
    final selectedClientId = RxString('');
    final selectedClientName = RxString('');
    final notesController = TextEditingController();
    final selectedDate = DateTime.now().obs;
    final selectedTime = TimeOfDay.now().obs;
    final employeesController = Get.find<EmployeesController>();

    // Cargar empleados al abrir el diálogo
    employeesController.loadEmployees();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nueva Cita',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Selector de Profesional
                _buildEmployeeSelector(controller, employeesController),
                const SizedBox(height: 16),

                // Selector de Servicio
                _buildServiceSelector(selectedServiceId),
                const SizedBox(height: 16),

                // Cliente seleccionado
                _buildClientSelector(
                  context,
                  selectedClientId,
                  selectedClientName,
                ),
                const SizedBox(height: 16),

                // Fecha y Hora
                _buildDateTimePickers(
                  context,
                  selectedDate,
                  selectedTime,
                ),
                const SizedBox(height: 16),

                // Notas
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleSubmit(
                        context,
                        formKey,
                        selectedServiceId,
                        selectedClientId,
                        selectedDate,
                        selectedTime,
                        notesController,
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector(
    AppointmentsController controller,
    EmployeesController employeesController,
  ) {
    return Obx(() => DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Profesional',
            border: OutlineInputBorder(),
          ),
          value: controller.selectedEmployee.value?.id,
          items: employeesController.employees
              .map((employee) => DropdownMenuItem(
                    value: employee.id,
                    child: Text('${employee.name} ${employee.lastname}'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              final employee = employeesController.employees
                  .firstWhere((e) => e.id == value);
              controller.selectEmployee(employee);
            }
          },
          validator: (value) =>
              value == null ? 'Seleccione un profesional' : null,
        ));
  }

  Widget _buildServiceSelector(RxString selectedServiceId) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Servicio',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      value: selectedServiceId.value.isEmpty ? null : selectedServiceId.value,
      items: controller.services.map((service) {
        return DropdownMenuItem<String>(
          value: service['id'].toString(),
          child: Text(service['name'].toString()),
        );
      }).toList(),
      onChanged: (value) => selectedServiceId.value = value ?? '',
      validator: (value) =>
          value == null || value.isEmpty ? 'Seleccione un servicio' : null,
    );
  }

  Widget _buildClientSelector(
    BuildContext context,
    RxString selectedClientId,
    RxString selectedClientName,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => Text(
                  selectedClientName.value.isEmpty
                      ? 'Ningún cliente seleccionado'
                      : selectedClientName.value,
                  style: TextStyle(
                    color: selectedClientName.value.isEmpty
                        ? Colors.grey
                        : Colors.black,
                  ),
                )),
          ),
          TextButton(
            onPressed: () async {
              final result = await ClientSelectorDialog.show(
                context,
                controller,
              );
              if (result != null) {
                selectedClientId.value = result['id'].toString();
                selectedClientName.value =
                    '${result['name']} ${result['lastname']}';
              }
            },
            child: const Text('Seleccionar Cliente'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickers(
    BuildContext context,
    Rx<DateTime> selectedDate,
    Rx<TimeOfDay> selectedTime,
  ) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate.value),
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.value,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) selectedDate.value = date;
                },
              )),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() => OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(selectedTime.value.format(context)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime.value,
                  );
                  if (time != null) selectedTime.value = time;
                },
              )),
        ),
      ],
    );
  }

  void _handleSubmit(
    BuildContext context,
    GlobalKey<FormState> formKey,
    RxString selectedServiceId,
    RxString selectedClientId,
    Rx<DateTime> selectedDate,
    Rx<TimeOfDay> selectedTime,
    TextEditingController notesController,
  ) {
    if (formKey.currentState?.validate() ?? false) {
      if (selectedClientId.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Debe seleccionar un cliente',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (controller.selectedEmployee.value == null) {
        Get.snackbar(
          'Error',
          'Debe seleccionar un profesional',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final selectedDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedTime.value.hour,
        selectedTime.value.minute,
      ).toUtc();

      controller.createAppointment(
        serviceId: selectedServiceId.value,
        clientId: selectedClientId.value,
        startTime: selectedDateTime,
        notes: notesController.text,
      );

      Navigator.pop(context);
    }
  }
}
