import 'package:flutter/cupertino.dart';
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: AppointmentFormDialog(controller: controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final selectedClientId = RxString('');
    final selectedClientName = RxString('');
    final notesController = TextEditingController();
    final selectedDate = DateTime.now().obs;
    final selectedTime = TimeOfDay.now().obs;
    final employeesController = Get.find<EmployeesController>();

    employeesController.loadEmployees();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              _buildEmployeeSelector(controller, employeesController),
              const SizedBox(height: 16),
              _buildServicesSelector(controller),
              const SizedBox(height: 8),
              _buildTotalPrice(controller),
              const SizedBox(height: 16),
              _buildClientSelector(
                  context, selectedClientId, selectedClientName),
              const SizedBox(height: 16),
              _buildDateTimePickers(context, selectedDate, selectedTime),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() => ElevatedButton(
                        onPressed: controller.selectedServiceIds.isEmpty
                            ? null
                            : () => _handleSubmit(
                                  context,
                                  formKey,
                                  selectedClientId,
                                  selectedDate,
                                  selectedTime,
                                  notesController,
                                ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector(
    AppointmentsController controller,
    EmployeesController employeesController,
  ) {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
      child: Obx(() => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Profesional',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Theme.of(Get.context!).primaryColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
            ),
            value: controller.selectedEmployee.value?.id,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            isExpanded: true,
            dropdownColor: Colors.white,
            menuMaxHeight: 300,
            items: employeesController.employees
                .map((employee) => DropdownMenuItem(
                      value: employee.id,
                      child: Text(
                        '${employee.name} ${employee.lastname}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                      ),
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
          )),
    );
  }

  Widget _buildServicesSelector(AppointmentsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.services.length,
                    itemBuilder: (context, index) {
                      final service = controller.services[index];
                      final serviceId = service['id'].toString();
                      return CheckboxListTile(
                        value:
                            controller.selectedServiceIds.contains(serviceId),
                        onChanged: (_) =>
                            controller.toggleServiceSelection(serviceId),
                        title: Text(
                          service['name'].toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          NumberFormat.currency(
                            locale: 'es',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(double.parse(service['price'].toString())),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        dense: true,
                      );
                    },
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPrice(AppointmentsController controller) {
    return Obx(() => Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total: ${NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 0).format(controller.totalPrice.value)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
  }

  Widget _buildClientSelector(
    BuildContext context,
    RxString selectedClientId,
    RxString selectedClientName,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      selectedClientName.value.isEmpty
                          ? 'Ningún cliente seleccionado'
                          : selectedClientName.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedClientName.value.isEmpty
                            ? Colors.grey[400]
                            : Colors.black87,
                        fontWeight: selectedClientName.value.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    )),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final result =
                  await ClientSelectorDialog.show(context, controller);
              if (result != null) {
                selectedClientId.value = result['id'].toString();
                selectedClientName.value =
                    '${result['name']} ${result['lastname']}';
              }
            },
            icon: const Icon(Icons.person_add_outlined, size: 20),
            label: const Text(
              'Seleccionar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
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
                  style: const TextStyle(fontSize: 13),
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
                label: Text(
                  DateFormat('h:mm a').format(DateTime(2024, 1, 1,
                      selectedTime.value.hour, selectedTime.value.minute)),
                ),
                onPressed: () => _showTimePicker(context, selectedTime),
              )),
        ),
      ],
    );
  }

  void _showTimePicker(BuildContext context, Rx<TimeOfDay> selectedTime) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime tempDateTime = DateTime(
          2024,
          1,
          1,
          selectedTime.value.hour,
          selectedTime.value.minute,
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  height: 250,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: tempDateTime,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newTime) {
                      tempDateTime = newTime;
                    },
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.deepPurple.shade200),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        selectedTime.value = TimeOfDay(
                          hour: tempDateTime.hour,
                          minute: tempDateTime.minute,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'ACEPTAR',
                        style: TextStyle(
                          color: Colors.deepPurple.shade200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit(
    BuildContext context,
    GlobalKey<FormState> formKey,
    RxString selectedClientId,
    Rx<DateTime> selectedDate,
    Rx<TimeOfDay> selectedTime,
    TextEditingController notesController,
  ) {
    if (formKey.currentState?.validate() ?? false) {
      if (selectedClientId.value.isEmpty) {
        Get.snackbar('Error', 'Debe seleccionar un cliente',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (controller.selectedEmployee.value == null) {
        Get.snackbar('Error', 'Debe seleccionar un profesional',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (controller.selectedServiceIds.isEmpty) {
        Get.snackbar('Error', 'Debe seleccionar al menos un servicio',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Crear DateTime con la fecha y hora seleccionada
      final localDateTime = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
        selectedDate.value.day,
        selectedTime.value.hour,
        selectedTime.value.minute,
      );

      // Convertir a UTC antes de enviar
      final utcDateTime = localDateTime.toUtc();
      print("Fecha local seleccionada: ${localDateTime.toString()}");
      print("Fecha UTC a enviar: ${utcDateTime.toIso8601String()}");

      controller.createAppointment(
        clientId: selectedClientId.value,
        startTime: utcDateTime,
        notes: notesController.text,
      );

      Navigator.pop(context);
    }
  }
}
