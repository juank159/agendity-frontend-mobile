import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'employee_feedback.dart';

/// Estado de una carga (catálogo de servicios o profesional a editar).
enum EmployeeLoadStatus { loading, ready, error }

/// Estado común del formulario de profesional (alta y edición, solo Owner).
///
/// Las reglas del dato (nombre, email, teléfono, contraseña, comisión y
/// horario) las valida el use case (`InvalidEmployeeDataFailure`); aquí solo
/// se convierte lo que elige el usuario. El catálogo de servicios se pide con
/// `GetServicesUseCase` (no con el controller de la feature services).
abstract class EmployeeFormController extends GetxController {
  static const defaultStart = '09:00';
  static const defaultEnd = '18:00';
  static const workWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday'
  ];

  static const servicesRequired =
      'Selecciona al menos un servicio para el profesional';

  final GetServicesUseCase _getServices;

  EmployeeFormController({required GetServicesUseCase getServicesUseCase})
      : _getServices = getServicesUseCase;

  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  /// Catálogo de servicios para elegir.
  final catalog = <ServiceEntity>[].obs;
  final catalogStatus = EmployeeLoadStatus.loading.obs;
  final catalogError = RxnString();

  /// Servicios elegidos → comisión (0–100).
  final commissions = <String, double>{}.obs;

  /// Precio propio de los servicios que ya lo tenían (no se edita aquí, pero
  /// se conserva al guardar).
  final Map<String, double> _customPrices = {};

  /// Días de trabajo → horario. Un día sin entrada es libre; sin ningún día,
  /// el profesional no tiene restricción de horario al agendar.
  final schedule = <String, WorkHours>{}.obs;

  final isSaving = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ------------------------------------------------------------ Catálogo

  Future<void> loadCatalog() async {
    catalogStatus.value = EmployeeLoadStatus.loading;
    catalogError.value = null;
    final result = await _getServices(NoParams());
    result.fold((failure) {
      catalogError.value = EmployeeFeedback.messageFor(failure);
      catalogStatus.value = EmployeeLoadStatus.error;
    }, (services) {
      catalog.assignAll(services.where((s) => s.id != null));
      catalogStatus.value = EmployeeLoadStatus.ready;
    });
  }

  /// Catálogo agrupado por categoría, en orden alfabético.
  Map<String, List<ServiceEntity>> get catalogByCategory {
    final grouped = <String, List<ServiceEntity>>{};
    for (final service in catalog) {
      grouped
          .putIfAbsent(service.category?.name ?? 'Sin categoría', () => [])
          .add(service);
    }
    final keys = grouped.keys.toList()..sort();
    return {for (final key in keys) key: grouped[key]!};
  }

  // ------------------------------------------------------------ Servicios

  bool isSelected(String serviceId) => commissions.containsKey(serviceId);

  void toggleService(String serviceId) {
    if (commissions.containsKey(serviceId)) {
      commissions.remove(serviceId);
    } else {
      commissions[serviceId] = 0;
    }
  }

  void setCommission(String serviceId, double percentage) {
    if (!commissions.containsKey(serviceId)) return;
    commissions[serviceId] = percentage.clamp(0, 100).toDouble();
  }

  // ------------------------------------------------------------- Horario

  bool isWorkDay(String day) => schedule.containsKey(day);

  void setWorkDay(String day, bool enabled) {
    if (enabled) {
      schedule.putIfAbsent(
          day, () => const WorkHours(start: defaultStart, end: defaultEnd));
    } else {
      schedule.remove(day);
    }
  }

  void setStart(String day, String value) {
    final current = schedule[day];
    if (current != null) {
      schedule[day] = WorkHours(start: value, end: current.end);
    }
  }

  void setEnd(String day, String value) {
    final current = schedule[day];
    if (current != null) {
      schedule[day] = WorkHours(start: current.start, end: value);
    }
  }

  // ----------------------------------------------------------- Formulario

  /// Horario por defecto de un alta: lunes a viernes de 9 a 18.
  @protected
  void useDefaultSchedule() {
    schedule.assignAll({
      for (final day in workWeek)
        day: const WorkHours(start: defaultStart, end: defaultEnd),
    });
  }

  /// Rellena el formulario con [employee] (edición).
  @protected
  void fill(EmployeeEntity employee) {
    nameController.text = employee.name;
    lastnameController.text = employee.lastname;
    emailController.text = employee.email;
    phoneController.text = employee.phone;
    passwordController.clear();
    commissions.assignAll({
      for (final entry in employee.serviceAssignments.entries)
        entry.key: entry.value.commissionPercentage,
    });
    _customPrices
      ..clear()
      ..addAll({
        for (final entry in employee.serviceAssignments.entries)
          if (entry.value.customPrice != null)
            entry.key: entry.value.customPrice!,
      });
    schedule.assignAll(employee.schedule);
  }

  /// Lo que escribió el usuario (el use case lo normaliza y valida).
  @protected
  EmployeeInput formInput() => EmployeeInput(
        name: nameController.text,
        lastname: lastnameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password:
            passwordController.text.isEmpty ? null : passwordController.text,
        services: {
          for (final entry in commissions.entries)
            entry.key: ServiceAssignment(
              serviceId: entry.key,
              commissionPercentage: entry.value,
              customPrice: _customPrices[entry.key],
            ),
        },
        schedule: Map.of(schedule),
      );

  /// Guarda con [save] (devuelve el failure o `null`). Exige al menos un
  /// servicio. `true` si se guardó.
  @protected
  Future<bool> runSave(Future<Failure?> Function() save) async {
    if (isSaving.value) return false;
    if (commissions.isEmpty) {
      AppSnackbar.warning(servicesRequired, title: 'Revisa los datos');
      return false;
    }
    isSaving.value = true;
    final failure = await save();
    isSaving.value = false;
    if (failure != null) {
      await EmployeeFeedback.show(failure);
      return false;
    }
    return true;
  }

  /// Guarda el formulario. `true` si se guardó.
  Future<bool> submit();
}
