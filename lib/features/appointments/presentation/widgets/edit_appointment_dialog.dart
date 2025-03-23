import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart'; // Añadida esta importación
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/professional_selector_dialog.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EditAppointmentDialog extends StatefulWidget {
  final AppointmentEntity appointment;
  final AppointmentsController controller;

  const EditAppointmentDialog({
    Key? key,
    required this.appointment,
    required this.controller,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context,
    AppointmentEntity appointment,
    AppointmentsController controller,
  ) {
    return showDialog<bool>(
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
          child: EditAppointmentDialog(
            appointment: appointment,
            controller: controller,
          ),
        ),
      ),
    );
  }

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  final formKey = GlobalKey<FormState>();
  final notesController = TextEditingController();
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  final RxList<String> selectedServiceIds = <String>[].obs;
  final RxDouble totalPrice = 0.0.obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    // Inicializar con los datos de la cita existente
    selectedDate = widget.appointment.startTime;
    selectedTime = TimeOfDay(
        hour: widget.appointment.startTime.hour,
        minute: widget.appointment.startTime.minute);
    notesController.text = widget.appointment.notes ?? '';

    // Intentar obtener el empleado
    _initializeEmployee();

    // Cargar servicios seleccionados
    _initializeServices();
  }

  void _initializeEmployee() async {
    final employeesController = Get.find<EmployeesController>();

    // Si el profesionalId existe, intentar encontrar el empleado
    if (widget.appointment.professionalId != null) {
      // Primero verificar si el empleado ya está en el controlador
      for (var employee in employeesController.employees) {
        if (employee.id == widget.appointment.professionalId) {
          widget.controller.selectedEmployee.value = employee;
          return;
        }
      }

      // Si no está, intentar obtenerlo
      try {
        final employee = await employeesController
            .getEmployeeById(widget.appointment.professionalId!);
        if (employee != null) {
          widget.controller.selectedEmployee.value = employee;
        }
      } catch (e) {
        print('Error al cargar el profesional: $e');
      }
    }
  }

  void _initializeServices() {
    // Para AppointmentEntity tenemos que intentar encontrar los IDs
    // basándonos en los nombres de servicio
    final availableServices = widget.controller.services;
    selectedServiceIds.clear(); // Limpiar los IDs existentes

    for (String serviceName in widget.appointment.serviceTypes) {
      for (var service in availableServices) {
        if (service['name'] == serviceName) {
          selectedServiceIds.add(service['id']);
          break;
        }
      }
    }

    // Calcular precio total
    updateTotalPrice();
  }

  void updateTotalPrice() {
    double total = 0.0;
    for (String serviceId in selectedServiceIds) {
      final service = widget.controller.services.firstWhere(
        (s) => s['id'] == serviceId,
        orElse: () => {'price': '0'},
      );
      total += double.parse(service['price']?.toString() ?? '0');
    }
    totalPrice.value = total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  Icons.edit_calendar,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Editar Cita',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenido principal en un scroll para que no afecte los botones
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Detalles del cliente (solo mostrar, no editar)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cliente',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                // Avatar/foto del cliente
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getClientInitials(
                                          widget.appointment.clientName),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.appointment.clientName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Selector de profesional
                    Obx(() => _buildProfessionalSelector(context)),

                    const SizedBox(height: 16),

                    // Selector de servicios
                    _buildServicesSummary(context),

                    const SizedBox(height: 16),

                    // Selectores de fecha y hora
                    _buildDateTimePickers(context),

                    const SizedBox(height: 16),

                    // Campo de notas
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botones de acción
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

                // Botón de guardar, deshabilitado si no hay servicios o profesional
                Obx(() => ElevatedButton.icon(
                      icon: isLoading.value
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ))
                          : const Icon(Icons.save, size: 18),
                      onPressed: selectedServiceIds.isNotEmpty &&
                              widget.controller.selectedEmployee.value !=
                                  null &&
                              !isLoading.value
                          ? _handleSubmit
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      label: const Text(
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
    );
  }

  Widget _buildProfessionalSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con icono
          Row(
            children: [
              Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Profesional',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Mostrar profesional seleccionado o mensaje si no hay ninguno
          _buildEmployeeDisplay(),

          const SizedBox(height: 12),

          // Botón para seleccionar o cambiar profesional
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final employeesController = Get.find<EmployeesController>();
                await ProfessionalSelectorDialog.show(
                  context,
                  widget.controller,
                  employeesController,
                );
              },
              icon: Icon(
                widget.controller.selectedEmployee.value == null
                    ? Icons.person_add_outlined
                    : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                widget.controller.selectedEmployee.value == null
                    ? 'Seleccionar profesional'
                    : 'Cambiar profesional',
                style: const TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar profesional seleccionado o mensaje si no hay ninguno
  Widget _buildEmployeeDisplay() {
    final selectedEmployee = widget.controller.selectedEmployee.value;

    if (selectedEmployee == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Ningún profesional seleccionado',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            fontStyle: FontStyle.normal,
          ),
        ),
      );
    } else {
      // Mostrar el profesional seleccionado con su información
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Avatar/foto del profesional
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: selectedEmployee.image != null &&
                      selectedEmployee.image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        selectedEmployee.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildEmployeeAvatar(selectedEmployee, context),
                      ),
                    )
                  : _buildEmployeeAvatar(selectedEmployee, context),
            ),

            const SizedBox(width: 12),

            // Nombre y rol del profesional
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedEmployee.name} ${selectedEmployee.lastname}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedEmployee.roles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Profesional',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Ícono de verificación
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEmployeeAvatar(EmployeeEntity employee, BuildContext context) {
    return Center(
      child: Text(
        _getEmployeeInitials(employee.name, employee.lastname),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildServicesSummary(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con etiqueta "Servicios"
          Row(
            children: [
              Icon(
                Icons.spa_outlined,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Servicios',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Información de servicios y precio
          Obx(() {
            if (selectedServiceIds.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Ningún servicio seleccionado',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.normal),
                ),
              );
            }

            final selectedServicesCount = selectedServiceIds.length;
            final serviceNames = _getSelectedServiceNames();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contador de servicios con precio total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$selectedServicesCount ${selectedServicesCount == 1 ? 'servicio' : 'servicios'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                              locale: 'es', symbol: '\$', decimalDigits: 0)
                          .format(totalPrice.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Lista de nombres de servicios
                if (serviceNames.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      serviceNames.join(', '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            );
          }),

          const SizedBox(height: 12),

          // Botón de modificar
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await showServiceSelectorDialog(context);
              },
              icon: Icon(
                selectedServiceIds.isEmpty
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                selectedServiceIds.isEmpty
                    ? 'Seleccionar servicios'
                    : 'Modificar selección',
                style: const TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showServiceSelectorDialog(BuildContext context) async {
    final services = widget.controller.services;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.spa_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Seleccionar Servicios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        final isSelected =
                            selectedServiceIds.contains(service['id']);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedServiceIds.add(service['id']);
                              } else {
                                selectedServiceIds.remove(service['id']);
                              }
                              updateTotalPrice();
                            });
                          },
                          title: Text(service['name']),
                          subtitle: Text(
                            NumberFormat.currency(
                                    locale: 'es',
                                    symbol: '\$',
                                    decimalDigits: 0)
                                .format(
                                    double.parse(service['price'].toString())),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          secondary: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(int.parse(service['color']
                                      ?.toString()
                                      .replaceFirst('#', '0xFF') ??
                                  '0xFF9E9E9E')),
                            ),
                          ),
                          activeColor: Theme.of(context).primaryColor,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Confirmar selección'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimePickers(BuildContext context) {
    return Row(
      children: [
        // Selector de fecha
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: OutlinedButton.icon(
              icon: Icon(
                Icons.calendar_today,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              label: Text(
                DateFormat('dd/MM/yy').format(selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      selectedDate.hour,
                      selectedDate.minute,
                    );
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Selector de hora
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: OutlinedButton.icon(
              icon: Icon(
                Icons.access_time,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              label: Text(
                selectedTime.format(context),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showTimePicker(context),
            ),
          ),
        ),
      ],
    );
  }

  void _showTimePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime tempDateTime =
            DateTime(2024, 1, 1, selectedTime.hour, selectedTime.minute);

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
                        setState(() {
                          selectedTime = TimeOfDay(
                            hour: tempDateTime.hour,
                            minute: tempDateTime.minute,
                          );
                        });
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

  void _handleSubmit() async {
    if (formKey.currentState?.validate() ?? false) {
      if (widget.controller.selectedEmployee.value == null) {
        Get.snackbar('Error', 'Debe seleccionar un profesional',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (selectedServiceIds.isEmpty) {
        Get.snackbar('Error', 'Debe seleccionar al menos un servicio',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Crear DateTime con la fecha y hora seleccionada
      final localDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Verificar si la fecha seleccionada es posterior a la actual
      if (localDateTime.isBefore(DateTime.now())) {
        Get.snackbar(
          'Error',
          'No se pueden crear citas en fechas pasadas',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isLoading.value = true;

      try {
        // Actualizar la cita
        await widget.controller.updateAppointment(
          appointmentId: widget.appointment.id!,
          professionalId: widget.controller.selectedEmployee.value!.id,
          serviceIds: selectedServiceIds.toList(),
          startTime: localDateTime,
          notes: notesController.text,
        );

        // Recargar las citas
        await widget.controller.fetchAppointments();

        // Cerrar el diálogo y mostrar mensaje de éxito
        Navigator.pop(context, true); // Devolver true para indicar éxito

        Get.snackbar(
          'Éxito',
          'Cita actualizada correctamente',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        print('=== ERROR AL ACTUALIZAR CITA ===');
        print('Error: $e');

        // Verificar si es un error de horario no disponible
        if (e.toString().toLowerCase().contains('horario no disponible')) {
          Get.snackbar(
            'Error',
            'El horario seleccionado no está disponible',
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
            duration: const Duration(seconds: 4),
          );
        } else {
          Get.snackbar(
            'Error',
            'No se pudo actualizar la cita: ${e.toString()}',
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
            duration: const Duration(seconds: 4),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }
  }

  List<String> _getSelectedServiceNames() {
    return selectedServiceIds
        .map((id) =>
            widget.controller.services
                .firstWhereOrNull((s) => s['id'] == id)?['name']
                ?.toString() ??
            '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _getEmployeeInitials(String name, String lastname) {
    String initials = '';
    if (name.isNotEmpty) initials += name[0].toUpperCase();
    if (lastname.isNotEmpty) initials += lastname[0].toUpperCase();
    return initials;
  }

  String _getClientInitials(String fullName) {
    final parts = fullName.split(' ');
    String initials = '';
    if (parts.isNotEmpty && parts[0].isNotEmpty)
      initials += parts[0][0].toUpperCase();
    if (parts.length > 1 && parts[1].isNotEmpty)
      initials += parts[1][0].toUpperCase();
    return initials;
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
