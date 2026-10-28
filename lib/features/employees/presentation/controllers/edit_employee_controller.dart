import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'employee_feedback.dart';
import 'employee_form_controller.dart';
import 'employee_navigation.dart';

/// Edición de un profesional (`/employees/edit`, id en
/// `arguments['employeeId']`). El email no se cambia aquí: cambiarlo exigiría
/// verificarlo de nuevo (pendiente en el backend, 2.33).
class EditEmployeeController extends EmployeeFormController {
  final GetEmployeeByIdUseCase _getEmployee;
  final UpdateEmployeeUseCase _update;

  EditEmployeeController({
    required GetEmployeeByIdUseCase getEmployeeByIdUseCase,
    required UpdateEmployeeUseCase updateEmployeeUseCase,
    required super.getServicesUseCase,
    String? employeeId,
  })  : _getEmployee = getEmployeeByIdUseCase,
        _update = updateEmployeeUseCase,
        employeeId = employeeId ??
            EmployeeNavigation.argument(EmployeeNavigation.employeeIdKey);

  final String employeeId;

  final status = EmployeeLoadStatus.loading.obs;
  final loadError = RxnString();
  final employee = Rxn<EmployeeEntity>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = EmployeeLoadStatus.loading;
    loadError.value = null;
    final result = await _getEmployee(employeeId);
    result.fold((failure) {
      loadError.value = EmployeeFeedback.messageFor(failure);
      status.value = EmployeeLoadStatus.error;
    }, (loaded) {
      employee.value = loaded;
      fill(loaded);
      status.value = EmployeeLoadStatus.ready;
      loadCatalog();
    });
  }

  @override
  Future<bool> submit() async {
    final current = employee.value;
    if (current == null) return false;
    final input = formInput().copyWith(email: current.email);
    final saved = await runSave(() async => (await _update(
            UpdateEmployeeParams(id: employeeId, input: input)))
        .fold((failure) => failure, (_) => null));
    if (!saved) return false;
    Get.back(result: true);
    AppSnackbar.success('Los cambios de ${current.fullName} se guardaron',
        title: 'Profesional actualizado');
    return true;
  }
}
