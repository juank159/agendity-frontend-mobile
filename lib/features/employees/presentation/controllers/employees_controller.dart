import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_deleted_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/restore_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'employee_feedback.dart';
import 'employee_navigation.dart';

/// Lista de profesionales (`/employees`, solo Owner): los del negocio y los
/// dados de baja, búsqueda y las acciones sobre cada uno (activar,
/// desactivar, eliminar, restaurar y verificar el email).
///
/// Ligado a su ruta (`EmployeesBinding`): ninguna otra feature lo usa.
/// Appointments pide los profesionales con `GetEmployeesUseCase`.
class EmployeesController extends GetxController {
  final GetEmployeesUseCase _getEmployees;
  final GetDeletedEmployeesUseCase _getDeleted;
  final ToggleEmployeeStatusUseCase _setActive;
  final DeleteEmployeeUseCase _delete;
  final RestoreEmployeeUseCase _restore;
  final DateTime Function() _now;

  EmployeesController({
    required GetEmployeesUseCase getEmployeesUseCase,
    required GetDeletedEmployeesUseCase getDeletedEmployeesUseCase,
    required ToggleEmployeeStatusUseCase toggleEmployeeStatusUseCase,
    required DeleteEmployeeUseCase deleteEmployeeUseCase,
    required RestoreEmployeeUseCase restoreEmployeeUseCase,
    DateTime Function()? clock,
  })  : _getEmployees = getEmployeesUseCase,
        _getDeleted = getDeletedEmployeesUseCase,
        _setActive = toggleEmployeeStatusUseCase,
        _delete = deleteEmployeeUseCase,
        _restore = restoreEmployeeUseCase,
        _now = clock ?? BusinessTimeZone.now;

  /// El Owner y sus empleados sin baja.
  final employees = <EmployeeEntity>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  /// Dados de baja (se cargan al abrir su vista).
  final deletedEmployees = <EmployeeEntity>[].obs;
  final isLoadingDeleted = false.obs;
  final deletedError = RxnString();
  bool _deletedLoaded = false;

  final showDeleted = false.obs;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  /// Profesionales con una acción en curso (deshabilita sus botones).
  final busyIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------- Lista

  /// Lista visible: la de la vista actual filtrada por la búsqueda.
  List<EmployeeEntity> get visibleEmployees =>
      _filter(showDeleted.value ? deletedEmployees : employees);

  bool get isLoadingCurrent =>
      showDeleted.value ? isLoadingDeleted.value : isLoading.value;

  String? get currentError =>
      showDeleted.value ? deletedError.value : error.value;

  List<EmployeeEntity> _filter(List<EmployeeEntity> source) {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return source.toList();
    return source
        .where((e) =>
            e.fullName.toLowerCase().contains(query) ||
            e.email.toLowerCase().contains(query) ||
            e.phone.contains(query))
        .toList();
  }

  /// Carga los profesionales. Si falla con la lista ya cargada, se conserva
  /// y se avisa.
  Future<void> loadEmployees() async {
    isLoading.value = true;
    error.value = null;
    final result = await _getEmployees(NoParams());
    isLoading.value = false;
    result.fold((failure) {
      final message = EmployeeFeedback.messageFor(failure);
      if (employees.isEmpty) {
        error.value = message;
      } else {
        AppSnackbar.error(message);
      }
    }, employees.assignAll);
  }

  Future<void> loadDeletedEmployees() async {
    isLoadingDeleted.value = true;
    deletedError.value = null;
    final result = await _getDeleted(NoParams());
    isLoadingDeleted.value = false;
    result.fold((failure) {
      final message = EmployeeFeedback.messageFor(failure);
      if (deletedEmployees.isEmpty) {
        deletedError.value = message;
      } else {
        AppSnackbar.error(message);
      }
    }, (list) {
      _deletedLoaded = true;
      deletedEmployees.assignAll(list);
    });
  }

  /// Recarga la vista actual (botón y "deslizar para actualizar").
  Future<void> refreshCurrent() =>
      showDeleted.value ? loadDeletedEmployees() : loadEmployees();

  void showDeletedView(bool value) {
    if (showDeleted.value == value) return;
    showDeleted.value = value;
    clearSearch();
    if (value && !_deletedLoaded) loadDeletedEmployees();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  // -------------------------------------------------------- Permisos

  /// El Owner no se borra ni se desactiva ni se edita desde aquí.
  bool canEdit(EmployeeEntity e) => !e.isOwner && !e.isDeleted;
  bool canChangeStatus(EmployeeEntity e) => !e.isOwner && !e.isDeleted;
  bool canDelete(EmployeeEntity e) => !e.isOwner && !e.isDeleted;
  bool canRestore(EmployeeEntity e) => e.isDeleted && !e.isOwner;
  bool canVerifyEmail(EmployeeEntity e) =>
      e.status == EmployeeStatus.pendingVerification;

  bool isBusy(EmployeeEntity e) => busyIds.contains(e.id);

  // -------------------------------------------------------- Navegación

  Future<void> openCreate() async {
    if (await EmployeeNavigation.openCreate() && !isClosed) {
      await loadEmployees();
    }
  }

  Future<void> openEdit(EmployeeEntity employee) async {
    if (!canEdit(employee)) return;
    if (await EmployeeNavigation.openEdit(employee) && !isClosed) {
      await loadEmployees();
    }
  }

  Future<void> openDetails(EmployeeEntity employee) =>
      EmployeeNavigation.openDetails(employee);

  // ---------------------------------------------------------- Acciones

  /// Activa o desactiva tras confirmar. Activar a un empleado sin el email
  /// verificado falla con `EmployeeEmailNotVerifiedFailure`: se explica el
  /// motivo y se ofrece verificarlo. `true` si cambió.
  Future<bool> setActive(EmployeeEntity employee, bool active) async {
    if (!canChangeStatus(employee) || isBusy(employee)) return false;
    if (!await EmployeeDialogs.confirmStatusChange(employee, active)) {
      return false;
    }

    final result = await _busy(
        employee,
        () => _setActive(ToggleEmployeeStatusParams(
            employeeId: employee.id, isActive: active)));
    return result.fold((failure) async {
      if (failure is EmployeeEmailNotVerifiedFailure) {
        if (await EmployeeDialogs.offerEmailVerification(
            employee, failure.message)) {
          return verifyEmail(employee);
        }
        return false;
      }
      await EmployeeFeedback.show(failure);
      return false;
    }, (_) async {
      _replace(employees, employee.copyWith(isActive: active));
      AppSnackbar.success(
          active
              ? '${employee.fullName} está activo'
              : '${employee.fullName} quedó inactivo',
          title: active ? 'Profesional activado' : 'Profesional desactivado');
      return true;
    });
  }

  /// Pide confirmación y un motivo opcional y da de baja. `true` si se borró.
  Future<bool> delete(EmployeeEntity employee) async {
    if (!canDelete(employee) || isBusy(employee)) return false;
    final reason = await EmployeeDialogs.askDeleteReason(employee);
    if (reason == null) return false;

    final result = await _busy(
        employee,
        () => _delete(
            DeleteEmployeeParams(employeeId: employee.id, reason: reason)));
    return result.fold((failure) async {
      await EmployeeFeedback.show(failure);
      return false;
    }, (_) async {
      employees.removeWhere((e) => e.id == employee.id);
      if (_deletedLoaded) {
        deletedEmployees.insert(
            0,
            employee.markDeleted(
                at: _now(), reason: reason.isEmpty ? null : reason));
      }
      AppSnackbar.success('${employee.fullName} fue eliminado',
          title: 'Profesional eliminado');
      return true;
    });
  }

  /// Restaura una baja tras confirmar. Queda inactivo si no verificó su
  /// email. `true` si se restauró.
  Future<bool> restore(EmployeeEntity employee) async {
    if (!canRestore(employee) || isBusy(employee)) return false;
    if (!await EmployeeDialogs.confirmRestore(employee)) return false;

    final result = await _busy(employee, () => _restore(employee.id));
    return result.fold((failure) async {
      await EmployeeFeedback.show(failure);
      return false;
    }, (restoration) async {
      deletedEmployees.removeWhere((e) => e.id == employee.id);
      employees.add(employee.markRestored(isActive: restoration.isActive));
      if (restoration.needsEmailVerification) {
        AppSnackbar.info(
            '${employee.fullName} quedó pendiente de verificar su email.',
            title: 'Profesional restaurado');
      } else {
        AppSnackbar.success('${employee.fullName} está activo de nuevo',
            title: 'Profesional restaurado');
      }
      return true;
    });
  }

  /// Abre la verificación del email; al verificar, el backend lo activa.
  Future<bool> verifyEmail(EmployeeEntity employee) async {
    final verified = await EmployeeNavigation.openVerification(employee);
    if (isClosed) return verified;
    if (verified) {
      _replace(employees,
          employee.copyWith(isActive: true, isEmailVerified: true));
      AppSnackbar.success('${employee.fullName} verificó su email y está activo',
          title: 'Email verificado');
    }
    return verified;
  }

  Future<T> _busy<T>(EmployeeEntity employee, Future<T> Function() run) async {
    busyIds.add(employee.id);
    try {
      return await run();
    } finally {
      busyIds.remove(employee.id);
    }
  }

  static void _replace(RxList<EmployeeEntity> list, EmployeeEntity updated) {
    final index = list.indexWhere((e) => e.id == updated.id);
    if (index >= 0) list[index] = updated;
  }
}
