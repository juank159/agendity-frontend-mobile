import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/appointments/presentation/widgets/professional_selector_dialog.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/subscription_plans_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/bindings/subscription_binding.dart';
import '../controllers/appointments_controller.dart';
import 'client_selector_dialog.dart';
import 'service_selector_dialog.dart';

class AppointmentFormDialog extends StatelessWidget {
  final AppointmentsController controller;
  final DateTime? initialDateTime;

  const AppointmentFormDialog({
    Key? key,
    required this.controller,
    this.initialDateTime,
  }) : super(key: key);
  static Future<void> show(
      BuildContext context, AppointmentsController controller,
      [DateTime? selectedDateTime]) async {
    // Primero verificar el estado de la suscripción
    final canCreateAppointment = await controller.checkSubscriptionStatus();

    if (!canCreateAppointment) {
      // Usar Get.toNamed para navegar a la pantalla de suscripción directamente
      Get.toNamed(GetRoutes.subscriptionPlans);
      return;
    }

    showDialog(
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
          child: AppointmentFormDialog(
            controller: controller,
            initialDateTime: selectedDateTime,
          ),
        ),
      ),
    );
  }

  // Método para mostrar el diálogo cuando se requiere suscripción
  static void _showSubscriptionRequiredDialog(
      BuildContext context, AppointmentsController controller) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.orange[700],
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Plan de prueba finalizado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.subscriptionMessage.value.isNotEmpty
                    ? controller.subscriptionMessage.value
                    : 'Has alcanzado el límite de citas de tu plan de prueba. Adquiere un plan para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo

                    // Registrar el binding si no está registrado
                    if (!Get.isRegistered<SubscriptionBinding>()) {
                      Get.lazyPut<SubscriptionBinding>(
                          () => SubscriptionBinding());
                    }

                    // Aplicar el binding y navegar a la pantalla de planes
                    SubscriptionBinding().dependencies();
                    Get.to(() => SubscriptionPlansScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver planes disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Solo cerrar el diálogo
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
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

    // Inicializar con la fecha/hora seleccionada si está disponible, de lo contrario usar la fecha actual
    final now = DateTime.now();
    final selectedDate =
        Rx<DateTime>(initialDateTime != null ? initialDateTime! : now);

    // Extraer la hora de la fecha inicial si está disponible
    final selectedTime = Rx<TimeOfDay>(initialDateTime != null
        ? TimeOfDay(
            hour: initialDateTime!.hour, minute: initialDateTime!.minute)
        : TimeOfDay.now());

    // Crear una variable para el controlador
    final employeesControllerRx = Rxn<EmployeesController>();

    // Intentar inicializar el módulo de empleados y obtener el controlador
    _initializeEmployeesController().then((controller) {
      employeesControllerRx.value = controller;
      if (controller != null) {
        controller.loadEmployees();
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            const Text(
              'Nueva Cita',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Contenido principal en un scroll para que no afecte los botones
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de profesional
                    Obx(() => employeesControllerRx.value != null
                        ? _buildProfessionalSelector(
                            context, controller, employeesControllerRx.value!)
                        : _buildErrorMessage(
                            context, "Cargando profesionales...")),

                    const SizedBox(height: 16),

                    // Selector de servicios
                    _buildServicesSummary(controller, context),

                    const SizedBox(height: 16),

                    // Selector de cliente
                    _buildClientSelector(
                        context, selectedClientId, selectedClientName),

                    const SizedBox(height: 16),

                    // Selectores de fecha y hora
                    _buildDateTimePickers(context, selectedDate, selectedTime),

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

            // Botones de acción (ahora fuera del scroll)
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
                      onPressed: controller.selectedServiceIds.isNotEmpty &&
                              controller.selectedEmployee.value != null &&
                              selectedClientId.value.isNotEmpty
                          ? () => _handleSubmit(
                                context,
                                formKey,
                                selectedClientId,
                                selectedDate,
                                selectedTime,
                                notesController,
                              )
                          : null,
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
    );
  }

  Widget _buildProfessionalSelector(
    BuildContext context,
    AppointmentsController controller,
    EmployeesController employeesController,
  ) {
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
          Obx(() {
            final selectedEmployee = controller.selectedEmployee.value;

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
            }

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
                                  _buildProfessionalAvatar(
                                      selectedEmployee, context),
                            ),
                          )
                        : _buildProfessionalAvatar(selectedEmployee, context),
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
          }),

          const SizedBox(height: 12),

          // Botón para seleccionar o cambiar profesional
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await ProfessionalSelectorDialog.show(
                  context,
                  controller,
                  employeesController,
                );
              },
              icon: Icon(
                controller.selectedEmployee.value == null
                    ? Icons.person_add_outlined
                    : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                controller.selectedEmployee.value == null
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

  // Función auxiliar para mostrar iniciales cuando no hay foto
  Widget _buildProfessionalAvatar(
      EmployeeEntity employee, BuildContext context) {
    return Center(
      child: Text(
        _getProfessionalInitials(employee.name, employee.lastname),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getProfessionalInitials(String name, String lastname) {
    String initials = '';
    if (name.isNotEmpty) initials += name[0].toUpperCase();
    if (lastname.isNotEmpty) initials += lastname[0].toUpperCase();
    return initials;
  }

  // Método para mostrar mensaje de error o carga
  Widget _buildErrorMessage(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // Método para inicializar de manera segura el EmployeesController
  Future<EmployeesController?> _initializeEmployeesController() async {
    try {
      // Primero intentar encontrar el controlador existente
      return Get.find<EmployeesController>();
    } catch (e) {
      print('Intentando inicializar EmployeesController desde cero');
      try {
        // Inicializar EmployeesModule manualmente
        await _initEmployeesModule();
        return Get.find<EmployeesController>();
      } catch (innerE) {
        print('Error inicializando EmployeesController: $innerE');
        return null;
      }
    }
  }

  // Método para inicializar el módulo de empleados
  Future<void> _initEmployeesModule() async {
    try {
      // Inicializar remotedatasource
      final dataSource = EmployeesRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      );
      Get.put(dataSource);

      // Inicializar repository
      final repository = EmployeesRepositoryImpl(dataSource);
      Get.put(repository);

      // Inicializar casos de uso
      final getEmployeesUseCase = GetEmployeesUseCase(repository);
      final getEmployeeByIdUseCase = GetEmployeeByIdUseCase(repository);
      final createEmployeeUseCase = CreateEmployeeUseCase(repository);

      Get.put(getEmployeesUseCase);
      Get.put(getEmployeeByIdUseCase);
      Get.put(createEmployeeUseCase);

      // Inicializar controller
      final controller = EmployeesController(
        getEmployeesUseCase: getEmployeesUseCase,
        getEmployeeByIdUseCase: getEmployeeByIdUseCase,
        createEmployeeUseCase: createEmployeeUseCase,
      );

      Get.put(controller);
      print('EmployeesController inicializado correctamente');
    } catch (e) {
      print('Error inicializando EmployeesModule: $e');
      throw e;
    }
  }

  Widget _buildServicesSummary(
    AppointmentsController controller,
    BuildContext context,
  ) {
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
            if (controller.selectedServiceIds.isEmpty) {
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

            final selectedServicesCount = controller.selectedServiceIds.length;
            final serviceNames = controller.getSelectedServiceNames();

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
                          .format(controller.totalPrice.value),
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
                await ServiceSelectorDialog.show(context, controller);
              },
              icon: Icon(
                controller.selectedServiceIds.isEmpty
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                controller.selectedServiceIds.isEmpty
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
        // Selector de fecha
        Expanded(
          child: Obx(() => Container(
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
                    DateFormat('dd/MM/yy').format(selectedDate.value),
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
                      initialDate: selectedDate.value,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) selectedDate.value = date;
                  },
                ),
              )),
        ),
        const SizedBox(width: 8),
        // Selector de hora
        Expanded(
          child: Obx(() => Container(
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
                    DateFormat('h:mm a').format(DateTime(2024, 1, 1,
                        selectedTime.value.hour, selectedTime.value.minute)),
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
                  onPressed: () => _showTimePicker(context, selectedTime),
                ),
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

      print(
          "Hora seleccionada por el usuario: ${selectedTime.value.format(context)}");
      print("Fecha y hora local: ${localDateTime.toString()}");

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

      controller.createAppointment(
        clientId: selectedClientId.value,
        startTime: localDateTime,
        notes: notesController.text,
      );

      Navigator.pop(context);
    }
  }
}
