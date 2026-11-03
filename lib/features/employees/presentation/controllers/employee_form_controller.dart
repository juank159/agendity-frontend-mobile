import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/usecases/employee_rules.dart';
import 'package:login_signup/common/entities/work_hours.dart';
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

  /// Comisión general en % (D-16): la de todo servicio sin excepción.
  final generalCommissionController = TextEditingController(text: '0');

  /// Lo escrito en [generalCommissionController], para pintar "Usar la
  /// general (X %)". `NaN` si no es un número.
  final generalCommission = 0.0.obs;

  /// Catálogo de servicios para elegir.
  final catalog = <ServiceEntity>[].obs;
  final catalogStatus = EmployeeLoadStatus.loading.obs;
  final catalogError = RxnString();

  /// Servicios elegidos → excepción de comisión (`null` = usa la general,
  /// D-16).
  final commissions = <String, double?>{}.obs;

  /// Precio propio de los servicios que ya lo tenían (no se edita aquí, pero
  /// se conserva al guardar).
  final Map<String, double> _customPrices = {};

  /// Días de trabajo → sus franjas (13.05: varias por día, p. ej. 10–12 y
  /// 16–18). Un día sin entrada es libre; sin ningún día, el profesional no
  /// tiene restricción de horario al agendar. Al editar se conservan todas
  /// las franjas aunque la pantalla muestre solo la primera (13.06 pinta el
  /// resto con [addRange]/[removeRange]).
  final schedule = <String, List<WorkHours>>{}.obs;

  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    generalCommissionController.addListener(_onGeneralChanged);
  }

  void _onGeneralChanged() =>
      generalCommission.value = parsePercentage(generalCommissionController.text);

  /// `12,5` o `12.5` → 12.5; vacío → 0; otra cosa → `NaN` (el use case la
  /// rechaza con "La comisión debe estar entre 0 y 100 %").
  static double parsePercentage(String text) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return 0;
    return double.tryParse(clean) ?? double.nan;
  }

  /// Error de la comisión general para el campo (en vivo, con el mismo
  /// texto que el use case): `null` si es un número de 0 a 100.
  String? get generalCommissionError =>
      EmployeeRules.isValidCommission(generalCommission.value)
          ? null
          : EmployeeRules.commissionInvalid;

  /// 12.0 → "12"; 12.5 → "12.5".
  static String percentageText(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  @override
  void onClose() {
    generalCommissionController.dispose();
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
      commissions[serviceId] = null;
    }
  }

  void setCommission(String serviceId, double percentage) {
    if (!commissions.containsKey(serviceId)) return;
    commissions[serviceId] = percentage.clamp(0, 100).toDouble();
  }

  /// El servicio usa la comisión general (`null`) o una propia, que arranca
  /// en el valor de la general.
  void useGeneralCommission(String serviceId, bool useGeneral) {
    if (!commissions.containsKey(serviceId)) return;
    final general = generalCommission.value;
    commissions[serviceId] = useGeneral
        ? null
        : (general.isNaN ? 0.0 : general.clamp(0, 100).toDouble());
  }

  // ------------------------------------------------------------- Horario

  bool isWorkDay(String day) => schedule[day]?.isNotEmpty ?? false;

  /// Franjas de [day] (vacía si es libre).
  List<WorkHours> rangesOf(String day) => schedule[day] ?? const [];

  void setWorkDay(String day, bool enabled) {
    if (enabled) {
      if (!isWorkDay(day)) {
        schedule[day] = const [WorkHours(start: defaultStart, end: defaultEnd)];
      }
    } else {
      schedule.remove(day);
    }
  }

  /// Inicio de la franja [index] de [day] (por defecto, la primera).
  void setStart(String day, String value, {int index = 0}) =>
      _updateRange(day, index, (h) => WorkHours(start: value, end: h.end));

  /// Fin de la franja [index] de [day] (por defecto, la primera).
  void setEnd(String day, String value, {int index = 0}) =>
      _updateRange(day, index, (h) => WorkHours(start: h.start, end: value));

  /// Otra franja en [day] después de la última (una hora más tarde, de una
  /// hora; si el día no trabajaba, la de por defecto). El use case revisa
  /// que no se pisen.
  void addRange(String day) {
    final ranges = rangesOf(day);
    if (ranges.isEmpty) return setWorkDay(day, true);
    final startMinute = _minutes(ranges.last.end) + 60;
    if (startMinute + 60 >= 24 * 60) return; // no cabe otra hoy
    schedule[day] = [
      ...ranges,
      WorkHours(start: _hhmm(startMinute), end: _hhmm(startMinute + 60)),
    ];
  }

  /// Quita la franja [index] de [day]; sin franjas, el día queda libre.
  void removeRange(String day, int index) {
    final ranges = [...rangesOf(day)];
    if (index < 0 || index >= ranges.length) return;
    ranges.removeAt(index);
    if (ranges.isEmpty) {
      schedule.remove(day);
    } else {
      schedule[day] = ranges;
    }
  }

  void _updateRange(
      String day, int index, WorkHours Function(WorkHours current) change) {
    final ranges = [...rangesOf(day)];
    if (index < 0 || index >= ranges.length) return;
    ranges[index] = change(ranges[index]);
    schedule[day] = ranges;
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  static String _hhmm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  // ----------------------------------------------------------- Formulario

  /// Horario por defecto de un alta: lunes a viernes de 9 a 18.
  @protected
  void useDefaultSchedule() {
    schedule.assignAll({
      for (final day in workWeek)
        day: const [WorkHours(start: defaultStart, end: defaultEnd)],
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
    generalCommissionController.text =
        percentageText(employee.commissionPercentage);
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
        schedule: {
          for (final entry in schedule.entries)
            entry.key: List.unmodifiable(entry.value),
        },
        commissionPercentage:
            parsePercentage(generalCommissionController.text),
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
