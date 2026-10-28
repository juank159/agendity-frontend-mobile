import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

/// Rutas con nombre de la feature y sus argumentos (un solo sitio para las
/// claves). Todas son `ownerOnly`; cada una tiene su binding.
///
/// `Get.toNamed` va sin tipo: GetX crea `GetPageRoute<dynamic>` y
/// `Get.toNamed<bool>` falla en el cast; el resultado se compara con `true`.
abstract final class EmployeeNavigation {
  static const employeeIdKey = 'employeeId';
  static const emailKey = 'email';
  static const nameKey = 'employeeName';

  /// Alta. `true` si se creó el profesional.
  static Future<bool> openCreate() async =>
      await Get.toNamed(GetRoutes.addEmployee) == true;

  /// Edición. `true` si se guardaron cambios.
  static Future<bool> openEdit(EmployeeEntity employee) async =>
      await Get.toNamed(GetRoutes.employeeEdit,
          arguments: {employeeIdKey: employee.id}) ==
      true;

  static Future<void> openDetails(EmployeeEntity employee) async {
    await Get.toNamed(GetRoutes.employeeDetails, arguments: employee);
  }

  /// Verificación del email. `true` si se verificó (el backend lo activa).
  static Future<bool> openVerification(EmployeeEntity employee) async =>
      await Get.toNamed(GetRoutes.verifyEmployeeEmail, arguments: {
        employeeIdKey: employee.id,
        emailKey: employee.email,
        nameKey: employee.fullName,
      }) ==
      true;

  /// Valor de texto de los argumentos de la ruta actual ('' si falta).
  static String argument(String key) {
    final args = Get.arguments;
    return args is Map ? (args[key]?.toString() ?? '') : '';
  }
}
