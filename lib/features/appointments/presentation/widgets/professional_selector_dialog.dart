import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import '../controllers/appointments_controller.dart';

class ProfessionalSelectorDialog extends StatelessWidget {
  final AppointmentsController appointmentsController;
  final EmployeesController employeesController;

  const ProfessionalSelectorDialog({
    Key? key,
    required this.appointmentsController,
    required this.employeesController,
  }) : super(key: key);

  static Future<EmployeeEntity?> show(
    BuildContext context,
    AppointmentsController appointmentsController,
    EmployeesController employeesController,
  ) async {
    // Guarda el profesional seleccionado para restaurarlo si el usuario cancela
    final originalSelectedEmployee =
        appointmentsController.selectedEmployee.value;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ProfessionalSelectorDialog(
            appointmentsController: appointmentsController,
            employeesController: employeesController,
          ),
        ),
      ),
    );

    // Si canceló, restaura la selección original
    if (result != true) {
      appointmentsController.selectedEmployee.value = originalSelectedEmployee;
      return null;
    }

    return appointmentsController.selectedEmployee.value;
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    // Asegura que empleados estén cargados
    if (employeesController.employees.isEmpty) {
      employeesController.loadEmployees();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Text(
            'Seleccionar Profesional',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Búsqueda
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Buscar Profesional',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  searchQuery.value = '';
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => searchQuery.value = value,
          ),

          const SizedBox(height: 16),

          // Lista de profesionales
          Obx(() {
            // Manejo de estado de carga
            if (employeesController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            // Cuando no hay profesionales
            if (employeesController.employees.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                    const Text('No hay profesionales disponibles'),
                  ],
                ),
              );
            }

            // Filtrar profesionales según búsqueda
            final filteredEmployees =
                employeesController.employees.where((employee) {
              final fullName =
                  '${employee.name} ${employee.lastname}'.toLowerCase();
              return fullName.contains(searchQuery.value.toLowerCase());
            }).toList();

            // Lista vacía después de filtrar
            if (filteredEmployees.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const Text('No se encontraron profesionales'),
                  ],
                ),
              );
            }

            // Lista de profesionales
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredEmployees.length,
                itemBuilder: (context, index) {
                  final employee = filteredEmployees[index];

                  return Obx(() {
                    final isSelected =
                        appointmentsController.selectedEmployee.value?.id ==
                            employee.id;

                    // Tarjeta de profesional con indicador de selección
                    return Card(
                      elevation: isSelected ? 4 : 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            appointmentsController.selectEmployee(employee),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Avatar/foto
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2)
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    _buildAvatar(employee, isSelected, context),
                              ),

                              const SizedBox(width: 16),

                              // Información
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${employee.name} ${employee.lastname}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (employee.roles.isNotEmpty)
                                      Text(
                                        'Profesional',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600]),
                                      ),
                                    if (employee.phone != null &&
                                        employee.phone!.isNotEmpty)
                                      Text(
                                        employee.phone!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500]),
                                      ),
                                  ],
                                ),
                              ),

                              // Indicador de selección
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 16),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 20),

          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
              ),
              Obx(() {
                final hasSelection =
                    appointmentsController.selectedEmployee.value != null;

                return ElevatedButton(
                  onPressed:
                      hasSelection ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirmar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
      EmployeeEntity employee, bool isSelected, BuildContext context) {
    if (employee.image != null && employee.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.network(
          employee.image!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildAvatarFallback(employee, isSelected, context),
        ),
      );
    }
    return _buildAvatarFallback(employee, isSelected, context);
  }

  Widget _buildAvatarFallback(
      EmployeeEntity employee, bool isSelected, BuildContext context) {
    return Center(
      child: Text(
        _getInitials(employee.name, employee.lastname),
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name, String lastname) {
    String initials = '';
    if (name.isNotEmpty) initials += name[0].toUpperCase();
    if (lastname.isNotEmpty) initials += lastname[0].toUpperCase();
    return initials;
  }
}
