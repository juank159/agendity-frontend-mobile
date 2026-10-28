import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/employees/domain/entities/employee_restoration.dart';

/// Respuesta de `PATCH /auth/employee/:id/restore`:
/// `{message, id, isActive, restoredAt}`.
class EmployeeRestorationModel {
  final String employeeId;
  final bool isActive;

  const EmployeeRestorationModel({
    required this.employeeId,
    required this.isActive,
  });

  /// [fallbackId] es el id pedido, por si la respuesta no lo trae.
  factory EmployeeRestorationModel.fromJson(Map<String, dynamic> json,
          {required String fallbackId}) =>
      EmployeeRestorationModel(
        employeeId: JsonRead.asString(json['id'], fallback: fallbackId),
        isActive: JsonRead.asBool(json['isActive'], fallback: false),
      );

  EmployeeRestoration toEntity() =>
      EmployeeRestoration(employeeId: employeeId, isActive: isActive);
}
