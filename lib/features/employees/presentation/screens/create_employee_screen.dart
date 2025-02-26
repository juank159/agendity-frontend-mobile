import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_form_section.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_schedule_section.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_services_section.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class CreateEmployeeScreen extends StatelessWidget {
  const CreateEmployeeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeesController>(
      init: Get.find<EmployeesController>(),
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
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de información personal
                      _buildSectionTitle('Información Personal'),
                      const SizedBox(height: 16),
                      EmployeeFormSection(controller: employeesController),

                      const SizedBox(height: 24),

                      // Sección de servicios
                      _buildSectionTitle('Servicios'),
                      const SizedBox(height: 8),
                      const Text(
                        'Seleccione los servicios que ofrecerá este profesional',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      EmployeeServicesSection(
                        employeesController: employeesController,
                        servicesController: servicesController,
                      ),

                      const SizedBox(height: 24),

                      // Sección de horario
                      _buildSectionTitle('Horario'),
                      const SizedBox(height: 8),
                      const Text(
                        'Configure el horario de trabajo para cada día',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      EmployeeScheduleSection(controller: employeesController),

                      const SizedBox(height: 32),

                      // Botón para crear
                      _buildCreateButton(employeesController),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildCreateButton(EmployeesController controller) {
    return Obx(() => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  try {
                    final result = await controller.createEmployee();
                    if (result) {
                      Get.snackbar(
                        'Éxito',
                        'Profesional creado correctamente',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green[100],
                        colorText: Colors.green[900],
                      );
                      Get.back();
                    }
                  } catch (e) {
                    print('Error creando empleado: $e');
                    Get.snackbar(
                      'Error',
                      'No se pudo crear el profesional',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red[100],
                      colorText: Colors.red[900],
                    );
                  }
                },
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Crear Profesional',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ));
  }
}
