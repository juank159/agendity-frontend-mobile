import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final EmployeeEntity employee;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final ServicesController servicesController =
        Get.find<ServicesController>();
    final EmployeesController employeesController =
        Get.find<EmployeesController>();

    // Añadir logs para depuración
    print('Mostrando detalles del empleado: ${employee.fullName}');
    print('ServiceIds: ${employee.serviceIds}');
    print(
        'ServiceAssignments: ${employee is EmployeeModel ? (employee as EmployeeModel).serviceAssignments : "No disponible"}');
    print('Schedule: ${employee.schedule}');
    print('Estado activo: ${employee.isActive}');

    // Cargar servicios si no están cargados
    if (servicesController.services.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        servicesController.loadServices();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Profesional'),
        centerTitle: true,
        backgroundColor: AppColors.cardIndicator,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Perfil del profesional
            _buildProfileHeader(employee),

            // Información detallada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información básica
                  _buildSection(
                    title: 'Información de Contacto',
                    icon: Icons.contact_mail,
                    children: [
                      _buildInfoRow(Icons.email, 'Email', employee.email),
                      _buildInfoRow(Icons.phone, 'Teléfono', employee.phone),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Servicios
                  _buildServicesList(employee, servicesController),

                  const SizedBox(height: 24),

                  // Horario
                  _buildSchedule(employee),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(EmployeeEntity employee) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cardIndicator,
            AppColors.cardIndicator.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              Hero(
                tag: 'avatar_${employee.id}',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: employee.image != null && employee.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            employee.image!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                employee.name.isNotEmpty
                                    ? employee.name[0].toUpperCase()
                                    : '?',
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
                          employee.name.isNotEmpty
                              ? employee.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            color: AppColors.cardIndicator,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                employee.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: employee.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      employee.isActive ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      employee.isActive ? 'Activo' : 'Inactivo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.cardIndicator),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(
      EmployeeEntity employee, ServicesController servicesController) {
    // Obtener las IDs de los servicios, preferiblemente desde serviceAssignments
    List<String> serviceIds = [];
    Map<String, double> commissions = {};

    if (employee is EmployeeModel && employee.serviceAssignments != null) {
      print('Usando serviceAssignments para los servicios');
      serviceIds = employee.serviceAssignments!.keys.toList();

      // Extraer comisiones
      employee.serviceAssignments!.forEach((id, assignment) {
        commissions[id] = assignment.commissionPercentage;
      });
    } else if (employee.serviceIds != null) {
      print('Usando serviceIds para los servicios');
      serviceIds = employee.serviceIds!;
    }

    // Si no hay IDs de servicio
    if (serviceIds.isEmpty) {
      return _buildSection(
        title: 'Servicios',
        icon: Icons.spa,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay servicios asignados a este profesional'),
          ),
        ],
      );
    }

    return Obx(() {
      if (servicesController.isLoading.value) {
        return _buildSection(
          title: 'Servicios',
          icon: Icons.spa,
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        );
      }

      // Filtrar los servicios que pertenecen a este empleado
      final employeeServices = servicesController.services
          .where((service) => serviceIds.contains(service.id))
          .toList();

      if (employeeServices.isEmpty) {
        return _buildSection(
          title: 'Servicios',
          icon: Icons.spa,
          children: const [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay servicios asociados'),
            ),
          ],
        );
      }

      return _buildSection(
        title: 'Servicios (${employeeServices.length})',
        icon: Icons.spa,
        children: [
          const SizedBox(height: 8),
          ...employeeServices.map((service) {
            final serviceId = service.id ?? '';
            final hasCommission = commissions.containsKey(serviceId);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.spa, color: Colors.blue[700]),
              ),
              title: Text(service.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio: ${formatCop(service.price)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasCommission)
                    Text(
                      'Comisión: ${commissions[serviceId]!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      );
    });
  }

  Widget _buildSchedule(EmployeeEntity employee) {
    print('Construyendo sección de horario con: ${employee.schedule}');

    if (employee.schedule == null || employee.schedule!.isEmpty) {
      return _buildSection(
        title: 'Horario',
        icon: Icons.schedule,
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No hay horario definido para este profesional'),
          ),
        ],
      );
    }

    final dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    final sortedDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final scheduleDays =
        sortedDays.where((day) => employee.schedule!.containsKey(day)).toList();

    return _buildSection(
      title: 'Horario',
      icon: Icons.schedule,
      children: [
        const SizedBox(height: 8),
        ...scheduleDays.map((day) {
          final daySchedule = employee.schedule![day];
          if (daySchedule == null ||
              daySchedule['start'] == null ||
              daySchedule['end'] == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    dayNames[day] ?? day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          daySchedule['start'] ?? '',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('a'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          daySchedule['end'] ?? '',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Método para el botón de activar/desactivar
  // Widget _buildStatusToggleButton(
  //     EmployeeEntity employee, EmployeesController controller) {
  //   final bool isActive = employee.isActive;

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
  //     child: Card(
  //       elevation: 3,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   isActive ? Icons.toggle_on : Icons.toggle_off,
  //                   color: isActive ? Colors.green : Colors.red,
  //                   size: 24,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   'Estado del Profesional',
  //                   style: const TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const Divider(),
  //             const SizedBox(height: 8),
  //             Text(
  //               isActive
  //                   ? 'Este profesional está actualmente activo y disponible para asignar citas.'
  //                   : 'Este profesional está inactivo y no puede recibir citas nuevas.',
  //               style: TextStyle(
  //                 color: isActive ? Colors.green[700] : Colors.red[700],
  //                 fontSize: 14,
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton.icon(
  //                 icon: Icon(
  //                   isActive ? Icons.person_off : Icons.person,
  //                   color: Colors.white,
  //                 ),
  //                 label: Text(
  //                   isActive ? 'DESACTIVAR PROFESIONAL' : 'ACTIVAR PROFESIONAL',
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: isActive ? Colors.orange : Colors.green,
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                   elevation: 2,
  //                 ),
  //                 onPressed: () {
  //                   showDialog(
  //                     context: Get.context!,
  //                     builder: (context) => ToggleStatusDialog(
  //                       employee: employee,
  //                       onConfirm: (newStatus) async {
  //                         final success = await controller.toggleEmployeeStatus(
  //                             employee.id, newStatus);

  //                         if (success) {
  //                           // Recargar el empleado para actualizar la UI
  //                           final updatedEmployee =
  //                               await controller.getEmployeeById(employee.id);
  //                           if (updatedEmployee != null) {
  //                             controller.selectEmployee(updatedEmployee);
  //                             // Refrescar la pantalla
  //                             Get.forceAppUpdate();
  //                           }
  //                         }
  //                       },
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
