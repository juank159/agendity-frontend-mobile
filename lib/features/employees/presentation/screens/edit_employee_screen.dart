// lib/features/employees/presentation/screens/edit_employee_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_services_section.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

// Definir el color personalizado para toda la aplicación
const Color customPrimaryColor =
    Color(0xFF2962FF); // Color azul que se ve en tus capturas

class EditEmployeeScreen extends StatelessWidget {
  final String employeeId;

  const EditEmployeeScreen({
    Key? key,
    required this.employeeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeesController>(
      init: Get.find<EmployeesController>(),
      initState: (_) {
        // Cargar datos del empleado para edición de forma explícita
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('Cargando datos del empleado con ID: $employeeId');
          Get.find<EmployeesController>().loadEmployeeForEditing(employeeId);
        });
      },
      builder: (employeesController) {
        return GetBuilder<ServicesController>(
          init: Get.find<ServicesController>(),
          builder: (servicesController) {
            // Cargar servicios inmediatamente
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (servicesController.services.isEmpty) {
                servicesController.loadServices();
              }
            });

            return Scaffold(
              appBar: AppBar(
                title: const Text('Editar Profesional'),
                centerTitle: true,
                backgroundColor: AppColors.cardIndicator,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    employeesController.cancelEdit();
                    Get.back();
                  },
                ),
              ),
              body: Obx(() {
                // Mostrar loading mientras se cargan los datos
                if (employeesController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.cardIndicator),
                  );
                }

                // Verificar explícitamente si se cargaron los datos
                if (employeesController.name.value.isEmpty &&
                    employeesController.lastname.value.isEmpty &&
                    employeesController.editingEmployeeId.value.isEmpty) {
                  print(
                      'Datos no cargados correctamente, intentando recargar...');
                  // Intentar cargar datos nuevamente
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    employeesController.loadEmployeeForEditing(employeeId);
                  });
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.cardIndicator),
                        SizedBox(height: 16),
                        Text('Cargando información del profesional...'),
                      ],
                    ),
                  );
                }

                // Si hay datos, mostrar la pantalla de edición
                print(
                    'Datos del empleado cargados: ${employeesController.name.value} ${employeesController.lastname.value}');

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de avatar/foto
                      _buildProfileSection(employeesController),

                      // Información básica
                      _buildInfoSection(
                        icon: Icons.person,
                        title: 'Información Básica',
                        children: [
                          _buildTextField(
                            label: 'Nombre *',
                            initialValue: employeesController.name.value,
                            onChanged: employeesController.updateName,
                            prefixIcon: Icons.person_outline,
                          ),
                          _buildTextField(
                            label: 'Apellido *',
                            initialValue: employeesController.lastname.value,
                            onChanged: employeesController.updateLastname,
                            prefixIcon: Icons.people_outline,
                          ),
                          _buildTextField(
                            label: 'Email *',
                            initialValue: employeesController.email.value,
                            onChanged:
                                (_) {}, // No hacemos nada con el cambio ya que es de solo lectura
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            readOnly: true, // Marcamos como solo lectura
                            suffix: Icon(Icons.lock_outline,
                                size: 16, color: Colors.grey[500]),
                          ),
                          _buildTextField(
                            label: 'Teléfono *',
                            initialValue: employeesController.phone.value,
                            onChanged: employeesController.updatePhone,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_android_outlined,
                          ),
                          _buildTextField(
                            label:
                                'Contraseña (dejar en blanco para no cambiar)',
                            initialValue: employeesController.password.value,
                            onChanged: employeesController.updatePassword,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline,
                          ),
                        ],
                      ),

                      // Sección de servicios
                      _buildInfoSection(
                        icon: Icons.spa,
                        title: 'Servicios',
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Seleccione los servicios que ofrecerá este profesional',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          EmployeeServicesSection(
                            employeesController: employeesController,
                            servicesController: servicesController,
                          ),
                        ],
                      ),

                      // Sección de horario
                      _buildHorarioSection(employeesController),

                      // Botones de acción
                      _buildActionButtons(employeesController),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileSection(EmployeesController controller) {
    final nameInitial = controller.name.value.isNotEmpty
        ? controller.name.value[0].toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      color: AppColors.cardIndicator,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar con opción para cambiar imagen
          GestureDetector(
            onTap: () {
              // TODO: Implementar selección de imagen
              Get.snackbar(
                'Próximamente',
                'La función para cambiar imagen estará disponible pronto',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: controller.selectedEmployee.value?.image != null &&
                          controller.selectedEmployee.value!.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            controller.selectedEmployee.value!.image!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                nameInitial,
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: AppColors.cardIndicator,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          nameInitial,
                          style: const TextStyle(
                            fontSize: 40,
                            color: AppColors.cardIndicator,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.cardIndicator,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Nombre del empleado
          Text(
            "${controller.name.value} ${controller.lastname.value}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.cardIndicator,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.cardIndicator,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Widget _buildTextField({
  //   required String label,
  //   required String initialValue,
  //   required Function(String) onChanged,
  //   TextInputType keyboardType = TextInputType.text,
  //   bool isPassword = false,
  //   IconData? prefixIcon,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           label,
  //           style: TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w500,
  //             color: Colors.grey[700],
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         TextFormField(
  //           initialValue: initialValue,
  //           onChanged: onChanged,
  //           keyboardType: keyboardType,
  //           obscureText: isPassword,
  //           decoration: InputDecoration(
  //             prefixIcon: prefixIcon != null
  //                 ? Icon(prefixIcon, color: Colors.grey[600])
  //                 : null,
  //             contentPadding:
  //                 const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //             filled: true,
  //             fillColor: Colors.grey[100],
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide.none,
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide(color: Colors.grey[300]!),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: const BorderSide(
  //                   color: AppColors.cardIndicator, width: 1.5),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    IconData? prefixIcon,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (readOnly) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: "Este campo no puede ser modificado",
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: isPassword,
            readOnly: readOnly,
            enabled: !readOnly,
            style: TextStyle(
              color: readOnly ? Colors.grey[700] : Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon,
                      color: readOnly ? Colors.grey[400] : Colors.grey[600])
                  : null,
              suffixIcon: suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: readOnly ? Colors.grey[200] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color:
                        readOnly ? Colors.grey[400]! : AppColors.cardIndicator,
                    width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          if (readOnly) ...[
            const SizedBox(height: 4),
            Text(
              "Este campo no puede ser modificado ya que el email es único y ha sido validado",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorarioSection(EmployeesController controller) {
    return _buildInfoSection(
      icon: Icons.schedule,
      title: 'Horario',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure los días y horarios de trabajo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.cardIndicator, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active los días en que el profesional trabaja y establezca su horario laboral. Los días inactivos no aparecerán disponibles para reservar citas.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildEmployeeScheduleSection(controller),
      ],
    );
  }

  Widget _buildEmployeeScheduleSection(EmployeesController controller) {
    final dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    return Obx(() {
      print(
          'Construyendo sección de horario. Días habilitados: ${controller.enabledDays}');
      print('Horario actual: ${controller.schedule}');

      return Column(
        children: controller.weekdays.map((day) {
          // Verificar si este día está habilitado
          final bool isDayEnabled = controller.enabledDays.contains(day);

          // Obtener el horario del día (si existe)
          final daySchedule =
              controller.schedule[day] ?? {'start': '09:00', 'end': '18:00'};

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDayEnabled
                    ? AppColors.cardIndicator.withOpacity(0.7)
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
                                ? AppColors.cardIndicator
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
                        activeColor: AppColors.cardIndicator,
                        onChanged: (value) {
                          print('Cambiando estado de $day a: $value');
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hora de inicio",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildTimeField(
                                      value: daySchedule['start'] ?? '09:00',
                                      onChanged: (value) {
                                        controller.updateSchedule(
                                            day, 'start', value);
                                        print(
                                            'Actualizado horario de $day: inicio=$value');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text('a',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hora de fin",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildTimeField(
                                      value: daySchedule['end'] ?? '18:00',
                                      onChanged: (value) {
                                        controller.updateSchedule(
                                            day, 'end', value);
                                        print(
                                            'Actualizado horario de $day: fin=$value');
                                      },
                                    ),
                                  ],
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
      );
    });
  }

  Widget _buildTimeField({
    required String value,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: Get.context!,
          initialTime: _parseTimeString(value),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.cardIndicator,
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
          color: AppColors.cardIndicator.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.cardIndicator.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.cardIndicator,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.access_time,
                size: 16, color: AppColors.cardIndicator),
          ],
        ),
      ),
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

  // lib/features/employees/presentation/screens/edit_employee_screen.dart

  // lib/features/employees/presentation/screens/edit_employee_screen.dart

  Widget _buildActionButtons(EmployeesController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Obx(() => ElevatedButton.icon(
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.0,
                    ))
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              controller.isLoading.value ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    await controller.updateEmployee();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardIndicator,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 54),
              elevation: 2,
            ),
          )),
    );
  }
}
