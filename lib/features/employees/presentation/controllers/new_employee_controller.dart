import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'employee_form_controller.dart';
import 'employee_navigation.dart';

/// Abre la verificación del email de [employee]; `true` si se verificó.
typedef EmployeeVerificationOpener = Future<bool> Function(
    EmployeeEntity employee);

/// Alta de un profesional (`/employees/new`). Nace **inactivo y sin
/// verificar** (2.16): tras crearlo se abre la verificación de su email y al
/// terminar (verificado o no) se vuelve a la lista con `result: true`.
class NewEmployeeController extends EmployeeFormController {
  final CreateEmployeeUseCase _create;
  final EmployeeVerificationOpener _openVerification;

  NewEmployeeController({
    required CreateEmployeeUseCase createEmployeeUseCase,
    required super.getServicesUseCase,
    EmployeeVerificationOpener? openVerification,
  })  : _create = createEmployeeUseCase,
        _openVerification =
            openVerification ?? EmployeeNavigation.openVerification;

  @override
  void onInit() {
    super.onInit();
    useDefaultSchedule();
    loadCatalog();
  }

  @override
  Future<bool> submit() async {
    EmployeeEntity? created;
    final saved = await runSave(() async =>
        (await _create(formInput())).fold((failure) => failure, (employee) {
          created = employee;
          return null;
        }));
    if (!saved || created == null) return false;

    final verified = await _openVerification(created!);
    Get.back(result: true);
    if (verified) {
      AppSnackbar.success(
          '${created!.fullName} verificó su email y ya está activo',
          title: 'Profesional creado');
    } else {
      AppSnackbar.info(
          '${created!.fullName} queda pendiente de verificación. Puedes '
          'verificar su email desde la lista.',
          title: 'Profesional creado');
    }
    return true;
  }
}
