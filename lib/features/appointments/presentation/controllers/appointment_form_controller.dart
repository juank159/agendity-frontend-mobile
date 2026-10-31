import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_available_slots_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_offered_by_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

enum SlotsStatus { idle, loading, ready, error }

/// Profesional elegido en el formulario (id y nombre para mostrar).
class SelectedProfessional {
  final String id;
  final String name;

  const SelectedProfessional({required this.id, required this.name});
}

/// Formulario de una cita: alta y edición con el mismo diálogo.
///
/// Es efímero: lo crea y lo borra su diálogo (`AppointmentFormDialog`). La
/// hora se elige entre las horas libres del backend (`available-slots`); la
/// disponibilidad, el cupo del plan y la hora pasada los decide el backend
/// al guardar, y aquí solo se avisa según el failure.
class AppointmentFormController extends GetxController {
  final CreateAppointmentUseCase _create;
  final UpdateAppointmentUseCase _update;
  final GetAvailableSlotsUseCase _getSlots;
  final GetServicesUseCase _getServices;
  final GetEmployeesUseCase _getProfessionals;
  final SessionController _session;
  final GetServicesOfferedByUseCase? _getOffered;
  final DateTime Function() _now;

  /// Servicios activos que hace el profesional elegido (10.03,
  /// `GetServicesOfferedByUseCase`; también para la empleada). `null` = aún
  /// no se sabe.
  final offered = Rxn<List<ServiceEntity>>();

  /// La cita que se edita; `null` = cita nueva.
  final AppointmentEntity? original;

  /// Hora sugerida al abrir (celda tocada en el calendario).
  final DateTime? _preferredStart;

  AppointmentFormController({
    required CreateAppointmentUseCase createAppointmentUseCase,
    required UpdateAppointmentUseCase updateAppointmentUseCase,
    required GetAvailableSlotsUseCase getAvailableSlotsUseCase,
    required GetServicesUseCase getServicesUseCase,
    required GetEmployeesUseCase getProfessionalsUseCase,
    required SessionController session,
    GetServicesOfferedByUseCase? getServicesOfferedByUseCase,
    this.original,
    DateTime? initialStart,
    DateTime Function()? now,
  })  : _create = createAppointmentUseCase,
        _update = updateAppointmentUseCase,
        _getSlots = getAvailableSlotsUseCase,
        _getServices = getServicesUseCase,
        _getProfessionals = getProfessionalsUseCase,
        _session = session,
        _getOffered = getServicesOfferedByUseCase,
        _now = now ?? BusinessTimeZone.now,
        _preferredStart = original?.startTime ?? initialStart;

  /// Con los use cases registrados por `<feature>_dependencies`.
  factory AppointmentFormController.fromDependencies({
    AppointmentEntity? original,
    DateTime? initialStart,
  }) =>
      AppointmentFormController(
        createAppointmentUseCase: Get.find(),
        updateAppointmentUseCase: Get.find(),
        getAvailableSlotsUseCase: Get.find(),
        getServicesUseCase: Get.find(),
        getProfessionalsUseCase: Get.find(),
        session: Get.find(),
        getServicesOfferedByUseCase:
            Get.isRegistered<GetServicesOfferedByUseCase>()
                ? Get.find<GetServicesOfferedByUseCase>()
                : null,
        original: original,
        initialStart: initialStart,
      );

  bool get isEditing => original != null;

  /// El Employee agenda solo para sí.
  bool get professionalIsFixed => _session.isOnlyEmployee;

  // --- Catálogo -----------------------------------------------------------
  final catalog = <ServiceEntity>[].obs;
  final professionals = <EmployeeEntity>[].obs;
  final isLoadingCatalog = false.obs;

  // --- Selección ----------------------------------------------------------
  final client = Rxn<AppointmentClient>();
  final professional = Rxn<SelectedProfessional>();
  final serviceIds = <String>[].obs;
  late final Rx<DateTime> day;
  final slot = Rxn<DateTime>();
  final notes = TextEditingController();

  // --- Horas libres -------------------------------------------------------
  final slots = <DateTime>[].obs;
  final slotsStatus = SlotsStatus.idle.obs;
  final slotsError = RxnString();
  int _slotsRequest = 0;

  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final current = original;
    final start = _preferredStart ?? _now();
    day = DateTime(start.year, start.month, start.day).obs;
    if (current != null) {
      client.value = current.client;
      professional.value = SelectedProfessional(
          id: current.professionalId,
          name: current.professionalName ?? 'Profesional');
      serviceIds.assignAll(current.serviceIds);
      notes.text = current.notes ?? '';
    } else if (professionalIsFixed) {
      professional.value = SelectedProfessional(
          id: _session.userId, name: _session.name ?? 'Yo');
    }
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    isLoadingCatalog.value = true;
    final servicesCall = _getServices(NoParams());
    final teamCall = professionalIsFixed ? null : _getProfessionals(NoParams());
    final services = await servicesCall;
    final team = await teamCall;
    isLoadingCatalog.value = false;
    services.fold(
      (failure) => AppSnackbar.error(failure.message,
          title: 'No se cargaron los servicios'),
      (loaded) => catalog.assignAll(loaded.where((s) => s.isActive)),
    );
    final pro = professional.value;
    if (pro != null) await _loadOffered(pro.id);
    // Sin la lista (p. ej. sin red) el selector queda vacío y lo dice.
    team?.fold(
      (_) {},
      (loaded) => professionals.assignAll(loaded.where((e) => e.canBeScheduled)),
    );
    await loadSlots();
  }

  // --- Cambios del usuario ------------------------------------------------

  void selectClient(ClientEntity selected) {
    final id = selected.id;
    if (id == null) return;
    client.value = AppointmentClient(
      id: id,
      name: selected.name,
      lastname: selected.lastname,
      phone: selected.phone.isEmpty ? null : selected.phone,
    );
  }

  void selectProfessional(EmployeeEntity employee) {
    if (professionalIsFixed) return;
    professional.value =
        SelectedProfessional(id: employee.id, name: employee.fullName);
    unawaited(_afterProfessionalChanged(employee));
  }

  Future<void> _afterProfessionalChanged(EmployeeEntity employee) async {
    await _loadOffered(employee.id);
    final known = offered.value;
    // Fuera los servicios que el nuevo profesional no hace (7.04-5).
    final dropped = serviceIds
        .where((id) => known != null
            ? !known.any((s) => s.id == id)
            : !employee.offersService(id))
        .toList();
    if (dropped.isNotEmpty) {
      serviceIds.removeWhere(dropped.contains);
      AppSnackbar.info(
          'Se quitaron servicios que ${employee.fullName} no realiza: '
          '${dropped.map(nameOf).join(', ')}',
          title: 'Servicios ajustados');
    }
    loadSlots();
  }

  /// Ficha del profesional elegido, si se conoce (respaldo de [offered]).
  EmployeeEntity? get selectedEmployee {
    final id = professional.value?.id;
    return id == null ? null : professionals.firstWhereOrNull((e) => e.id == id);
  }

  Future<void> _loadOffered(String professionalId) async {
    final useCase = _getOffered;
    if (useCase == null) return;
    final result = await useCase(professionalId);
    if (professional.value?.id != professionalId) return; // cambió
    offered.value = result.fold((_) => null, (list) => list);
  }

  /// Servicios que se pueden elegir: los activos que hace el profesional
  /// elegido (`GetServicesOfferedByUseCase`; si no se pudo leer, la regla
  /// `offersService` sobre la ficha del profesional).
  List<ServiceEntity> get offeredCatalog {
    final known = offered.value;
    if (known != null) return known.where((s) => s.isActive).toList();
    final employee = selectedEmployee;
    if (employee == null) return catalog.toList();
    return catalog
        .where((s) => s.id != null && employee.offersService(s.id!))
        .toList();
  }

  void setServices(List<String> ids) {
    serviceIds.assignAll(ids);
    loadSlots();
  }

  void selectDay(DateTime value) {
    day.value = DateTime(value.year, value.month, value.day);
    loadSlots();
  }

  void selectSlot(DateTime value) => slot.value = value;

  // --- Resumen -------------------------------------------------------------

  /// Servicio [id]: precio guardado en la cita si ya estaba en ella (editar
  /// los conserva, 2.29); si no, el del catálogo.
  double priceOf(String id) {
    final line = original?.services.firstWhereOrNull((s) => s.serviceId == id);
    if (line != null) return line.price;
    return catalog.firstWhereOrNull((s) => s.id == id)?.price ?? 0;
  }

  String nameOf(String id) =>
      catalog.firstWhereOrNull((s) => s.id == id)?.name ??
      original?.services.firstWhereOrNull((s) => s.serviceId == id)?.name ??
      'Servicio';

  int durationOf(String id) {
    final minutes = catalog.firstWhereOrNull((s) => s.id == id)?.duration ??
        original?.services
            .firstWhereOrNull((s) => s.serviceId == id)
            ?.durationMinutes;
    return minutes == null || minutes <= 0
        ? AppointmentServiceLine.defaultDurationMinutes
        : minutes;
  }

  double get totalPrice =>
      serviceIds.fold(0, (sum, id) => sum + priceOf(id));

  int get totalMinutes => serviceIds.fold(0, (sum, id) => sum + durationOf(id));

  bool get canSubmit =>
      client.value != null &&
      professional.value != null &&
      serviceIds.isNotEmpty &&
      slot.value != null &&
      !isSaving.value;

  // --- Horas libres -------------------------------------------------------

  /// Pide las horas libres del profesional el día elegido para los servicios
  /// elegidos. La hora elegida se conserva si sigue libre.
  Future<void> loadSlots() async {
    final pro = professional.value;
    final request = ++_slotsRequest;
    if (pro == null || serviceIds.isEmpty) {
      slots.clear();
      slot.value = null;
      slotsStatus.value = SlotsStatus.idle;
      return;
    }
    slotsStatus.value = SlotsStatus.loading;
    slotsError.value = null;
    final result = await _getSlots(AvailableSlotsQuery(
      professionalId: pro.id,
      day: day.value,
      serviceIds: serviceIds.toList(),
    ));
    if (request != _slotsRequest) return;
    result.fold(
      (failure) {
        slots.clear();
        slot.value = null;
        slotsError.value = failure.message;
        slotsStatus.value = SlotsStatus.error;
      },
      (free) {
        final options = [...free];
        final current = original?.startTime;
        // La hora actual de la cita que se edita está ocupada por ella misma:
        // se ofrece igualmente (el backend la excluye al comprobar).
        // Una cita por mover (10.03) no puede quedarse en su hora: no se
        // ofrece.
        if (current != null &&
            !(original?.needsReschedule ?? false) &&
            _sameDay(current, day.value) &&
            !options.any((s) => s.isAtSameMomentAs(current))) {
          options.add(current);
          options.sort();
        }
        slots.assignAll(options);
        final wanted = slot.value ?? _preferredStart;
        slot.value = wanted == null
            ? null
            : options.firstWhereOrNull((s) => s.isAtSameMomentAs(wanted));
        slotsStatus.value = SlotsStatus.ready;
      },
    );
  }

  /// La hora elegida es la que ya tenía la cita que se edita.
  bool isCurrentSlot(DateTime value) =>
      original != null && value.isAtSameMomentAs(original!.startTime);

  // --- Guardar --------------------------------------------------------------

  /// Crea o edita la cita. Devuelve la cita guardada (el diálogo se cierra)
  /// o `null` si falló, después de avisar.
  Future<AppointmentEntity?> submit() async {
    if (!canSubmit) return null;
    final current = original;
    if (current != null) {
      final changes = AppointmentChanges.between(
        current,
        clientId: client.value!.id,
        professionalId: professional.value!.id,
        serviceIds: serviceIds.toList(),
        start: slot.value,
        notes: notes.text,
      );
      if (changes.isEmpty) {
        AppSnackbar.info('No hay cambios que guardar');
        return current;
      }
      return _save(
        () => _update(
            UpdateAppointmentParams(original: current, changes: changes)),
        'Cita actualizada',
      );
    }
    return _save(
      () => _create(NewAppointment(
        clientId: client.value!.id,
        professionalId: professional.value!.id,
        serviceIds: serviceIds.toList(),
        start: slot.value!,
        notes: notes.text,
      )),
      'Cita agendada',
    );
  }

  Future<AppointmentEntity?> _save(
    Future<Either<Failure, AppointmentEntity>> Function() call,
    String successMessage,
  ) async {
    isSaving.value = true;
    final result = await call();
    isSaving.value = false;
    return result.fold(
      (failure) {
        AppointmentFeedback.showSaveFailure(failure);
        if (failure is SlotUnavailableFailure ||
            failure is AppointmentInPastFailure) {
          loadSlots();
        }
        return null;
      },
      (saved) {
        AppSnackbar.success(successMessage);
        return saved;
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void onClose() {
    notes.dispose();
    super.onClose();
  }
}
