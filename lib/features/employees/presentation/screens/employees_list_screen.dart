import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/screens/create_employee_screen.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class EmployeesListScreen extends StatelessWidget {
  const EmployeesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar GetBuilder para reaccionar a los cambios
    return GetBuilder<EmployeesController>(
      init: Get.find<EmployeesController>(),
      initState: (_) {
        // Este callback se ejecuta cuando se inicializa el widget
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<EmployeesController>().loadEmployees();
        });
      },
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profesionales'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Get.offAllNamed('/');
              },
            ),
            centerTitle: true,
            actions: [
              // Añadir botón de actualizar
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  controller.loadEmployees();
                  Get.snackbar(
                    'Actualizado',
                    'Lista de profesionales actualizada',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: controller.loadEmployees,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.employees.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.employees.length,
                itemBuilder: (context, index) {
                  final employee = controller.employees[index];
                  return _buildEmployeeCard(employee, context);
                },
              );
            }),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              try {
                print('Iniciando navegación a CreateEmployeeScreen...');

                // Asegurarnos de que los controladores estén disponibles
                final employeesController = Get.find<EmployeesController>();

                // Verificar si ServicesController está registrado
                if (!Get.isRegistered<ServicesController>()) {
                  print('ServicesController no encontrado, registrando...');
                  Get.put(
                    ServicesController(getServicesUseCase: Get.find()),
                    permanent: true,
                  );
                }

                // Pre-cargar servicios antes de navegar
                final servicesController = Get.find<ServicesController>();

                // Cargar servicios explícitamente
                if (servicesController.services.isEmpty) {
                  print('Pre-cargando servicios...');
                  await servicesController.loadServices();
                }

                // Navegar a la pantalla
                print('Navegando a CreateEmployeeScreen...');
                Get.to(
                  () => const CreateEmployeeScreen(),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 250),
                );
              } catch (e) {
                print('Error al navegar: $e');
                Get.snackbar(
                  'Error',
                  'No se pudo abrir la pantalla de creación',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay profesionales registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade tu primer profesional pulsando el botón +',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(200, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              try {
                if (!Get.isRegistered<ServicesController>()) {
                  Get.put(
                    ServicesController(getServicesUseCase: Get.find()),
                    permanent: true,
                  );
                }
                Get.to(() => const CreateEmployeeScreen());
              } catch (e) {
                print('Error navegando desde estado vacío: $e');
                Get.snackbar(
                  'Error',
                  'No se pudo abrir la pantalla de creación',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text(
              'Crear Profesional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeEntity employee, BuildContext context) {
    final bool isActive = employee.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isActive ? AppColors.primary : Colors.grey,
          radius: 24,
          child: Text(
            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(employee.email),
            if (employee.phone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(employee.phone),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  color: isActive ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(context, employee),
        ),
        onTap: () => _showEmployeeDetails(context, employee),
      ),
    );
  }

  void _showOptions(BuildContext context, EmployeeEntity employee) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Ver detalles'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmployeeDetails(context, employee);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar edición de empleado
                },
              ),
              ListTile(
                leading: Icon(
                  employee.isActive ? Icons.person_off : Icons.person,
                  color: employee.isActive ? Colors.red : Colors.green,
                ),
                title: Text(
                  employee.isActive ? 'Desactivar' : 'Activar',
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar activación/desactivación
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmployeeDetails(BuildContext context, EmployeeEntity employee) {
    Get.toNamed('/employee-details', arguments: employee);
    // TODO: Implementar navegación a detalles del empleado
  }
}
