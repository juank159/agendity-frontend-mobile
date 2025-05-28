import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_services_section.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

// Definir el color personalizado para toda la aplicación (usando AppColors.primary)
const Color customPrimaryColor = AppColors.cardIndicator;

class CreateEmployeeScreen extends StatelessWidget {
  const CreateEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeesController>(
      init: Get.find<EmployeesController>(),
      initState: (_) {
        // Limpiar el formulario cuando se inicializa la pantalla
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final controller = Get.find<EmployeesController>();
          controller.clearForm(); // Asegurarnos de que se limpie el formulario
          print('Formulario limpiado en CreateEmployeeScreen');
        });
      },
      builder: (employeesController) {
        return GetBuilder<ServicesController>(
          init: Get.find<ServicesController>(),
          builder: (servicesController) {
            // Cargar servicios inmediatamente al construir la pantalla
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (servicesController.services.isEmpty ||
                  servicesController.services.length == 0) {
                print('Cargando servicios desde CreateEmployeeScreen...');
                servicesController.loadServices();
              } else {
                print(
                    'Ya hay ${servicesController.services.length} servicios cargados');
              }
            });

            return Scaffold(
              appBar: AppBar(
                title: const Text('Crear Profesional'),
                centerTitle: true,
                backgroundColor: customPrimaryColor,
              ),
              body: Obx(() {
                // Mostrar loading mientras se cargan los datos
                if (employeesController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: customPrimaryColor),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de avatar/foto de perfil
                      _buildProfileSection(employeesController),

                      // Información básica
                      _buildInfoSection(
                        icon: Icons.person,
                        title: 'Información Básica',
                        children: [
                          _buildTextField(
                            label: 'Nombre *',
                            controller: employeesController.nameController,
                            onChanged: employeesController.updateName,
                            prefixIcon: Icons.person_outline,
                          ),
                          _buildTextField(
                            label: 'Apellido *',
                            controller: employeesController.lastnameController,
                            onChanged: employeesController.updateLastname,
                            prefixIcon: Icons.people_outline,
                          ),
                          _buildTextField(
                            label: 'Email *',
                            controller: employeesController.emailController,
                            onChanged: employeesController.updateEmail,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                          _buildTextField(
                            label: 'Teléfono *',
                            controller: employeesController.phoneController,
                            onChanged: employeesController.updatePhone,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_android_outlined,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                          _buildTextField(
                            label: 'Contraseña *',
                            controller: employeesController.passwordController,
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

                      // Botón para crear
                      _buildCreateButton(employeesController),

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
    // Usamos el primer carácter del nombre si está disponible, o '?' si está vacío
    final nameInitial = controller.name.value.isNotEmpty
        ? controller.name.value[0].toUpperCase()
        : 'N';

    return Container(
      width: double.infinity,
      color: customPrimaryColor,
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
                  child: Text(
                    nameInitial,
                    style: TextStyle(
                      fontSize: 40,
                      color: customPrimaryColor,
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
                      color: customPrimaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Nombre del profesional (si ya se ha introducido)
          Text(
            controller.name.value.isNotEmpty ||
                    controller.lastname.value.isNotEmpty
                ? "${controller.name.value} ${controller.lastname.value}"
                : "Nuevo Profesional",
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
                  color: customPrimaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: customPrimaryColor,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: isPassword,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.grey[600])
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey[100],
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
                borderSide:
                    const BorderSide(color: customPrimaryColor, width: 1.5),
              ),
            ),
          ),
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
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
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
                    ? customPrimaryColor.withOpacity(0.7)
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
                            color:
                                isDayEnabled ? customPrimaryColor : Colors.grey,
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
                        activeColor: customPrimaryColor,
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
                  primary: customPrimaryColor,
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
          color: customPrimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: customPrimaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: customPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.access_time, size: 16, color: customPrimaryColor),
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

  // Widget _buildCreateButton(EmployeesController controller) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
  //     child: SizedBox(
  //       width: double.infinity,
  //       child: ElevatedButton.icon(
  //         icon: const Icon(Icons.add_circle_outline, color: Colors.white),
  //         label: const Text('CREAR PROFESIONAL'),
  //         onPressed: controller.isLoading.value
  //             ? null
  //             : () async {
  //                 try {
  //                   // Usar el método de verificación antes de crear
  //                   final result = await controller.createEmployeeAndVerify();

  //                   if (result) {
  //                     // Si todo salió bien (verificación y creación), volvemos a la lista
  //                     Get.back();
  //                   }
  //                   // Si result es false, ya se mostró un mensaje de error/advertencia
  //                 } catch (e) {
  //                   print('Error en el proceso: $e');
  //                   Get.snackbar(
  //                     'Error',
  //                     'Ocurrió un error inesperado: ${e.toString()}',
  //                     snackPosition: SnackPosition.TOP,
  //                     backgroundColor: Colors.red[100],
  //                     colorText: Colors.red[900],
  //                   );
  //                 }
  //               },
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: customPrimaryColor,
  //           foregroundColor: Colors.white,
  //           padding: const EdgeInsets.symmetric(vertical: 16),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCreateButton(EmployeesController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: controller.isLoading.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ))
              : const Icon(Icons.add_circle_outline, color: Colors.white),
          label: Text(
            controller.isLoading.value ? 'CREANDO...' : 'CREAR PROFESIONAL',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  try {
                    // Mostrar una animación de carga
                    controller.isLoading.value = true;

                    // Usar el método de verificación antes de crear
                    final result = await controller.createEmployeeAndVerify();

                    // Si todo salió bien (verificación y creación), volvemos a la lista
                    if (result) {
                      // El manejo de éxito se hace dentro de createEmployeeAndVerify
                    }
                    // Si result es false, ya se mostró un mensaje de error/advertencia
                  } catch (e) {
                    print('Error en el proceso: $e');
                    Get.snackbar(
                      'Error',
                      'Ocurrió un error inesperado: ${e.toString()}',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red[50],
                      colorText: Colors.red[900],
                      margin: const EdgeInsets.all(10),
                      borderRadius: 10,
                      icon: const Icon(Icons.error_outline, color: Colors.red),
                      duration: const Duration(seconds: 5),
                    );
                  } finally {
                    controller.isLoading.value = false;
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: customPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
